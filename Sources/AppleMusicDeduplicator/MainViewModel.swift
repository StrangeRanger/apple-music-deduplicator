import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class MainViewModel {
    enum WorkState: Equatable {
        case idle
        case loading
        case scanning
        case applying
    }

    private(set) var playlists: [PlaylistSummary] = []
    private(set) var selectedPlaylistIDs = Set<String>()
    private(set) var duplicates: [DuplicateSong] = []
    private(set) var keepSelections: [String: Set<String>] = [:]
    private(set) var workState: WorkState = .idle
    var filterText = ""
    var statusMessage = ""
    var errorMessage: String?
    var lastRemovalResult: RemovalResult?
    private(set) var removalProgress: RemovalProgress?

    private let musicAutomation: MusicAutomation

    init(musicAutomation: MusicAutomation = MusicAutomation()) {
        self.musicAutomation = musicAutomation
    }

    var filteredPlaylists: [PlaylistSummary] {
        guard !filterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return playlists
        }

        return playlists.filter {
            $0.name.localizedCaseInsensitiveContains(filterText)
                || $0.sourceName.localizedCaseInsensitiveContains(filterText)
                || $0.kindLabel.localizedCaseInsensitiveContains(filterText)
        }
    }

    var canScan: Bool {
        selectedPlaylistIDs.count >= 2 && workState == .idle
    }

    var pendingRemovals: [RemovalRequest] {
        DuplicateAnalyzer.removalRequests(duplicates: duplicates, keepSelections: keepSelections)
    }

    var selectedCountText: String {
        "\(selectedPlaylistIDs.count) selected"
    }

    func loadPlaylists() {
        guard workState == .idle else { return }

        workState = .loading
        errorMessage = nil
        lastRemovalResult = nil
        removalProgress = nil
        duplicates = []
        keepSelections = [:]
        statusMessage = "Loading playlists"

        Task {
            do {
                playlists = try await musicAutomation.loadPlaylists()
                selectedPlaylistIDs = selectedPlaylistIDs.intersection(Set(playlists.map(\.id)))
                statusMessage = "\(playlists.count) playlists"
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Playlist load failed"
            }

            workState = .idle
        }
    }

    func setSelected(_ isSelected: Bool, playlistID: String) {
        guard workState == .idle else { return }

        if isSelected {
            selectedPlaylistIDs.insert(playlistID)
        } else {
            selectedPlaylistIDs.remove(playlistID)
        }

        duplicates = []
        keepSelections = [:]
        lastRemovalResult = nil
        removalProgress = nil
    }

    func scanSelectedPlaylists() {
        guard canScan else { return }

        let playlistIDs = selectedPlaylistIDs
        workState = .scanning
        errorMessage = nil
        lastRemovalResult = nil
        removalProgress = nil
        duplicates = []
        keepSelections = [:]
        statusMessage = "Scanning selected playlists"

        Task {
            defer { workState = .idle }

            do {
                let scannedDuplicates = try await musicAutomation.scanPlaylists(withIDs: playlistIDs)
                guard selectedPlaylistIDs == playlistIDs else { return }

                duplicates = scannedDuplicates
                keepSelections = Dictionary(
                    uniqueKeysWithValues: scannedDuplicates.map {
                        ($0.id, Set($0.occurrences.map(\.playlistID)))
                    }
                )
                statusMessage = scannedDuplicates.isEmpty
                    ? "No duplicates"
                    : "\(scannedDuplicates.count) duplicate songs"
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Scan failed"
            }
        }
    }

    func setKeep(_ keep: Bool, duplicateID: String, playlistID: String) {
        guard workState == .idle,
              let duplicate = duplicates.first(where: { $0.id == duplicateID }),
              let occurrence = duplicate.occurrences.first(where: { $0.playlistID == playlistID }),
              occurrence.canRemove || keep else {
            return
        }

        var kept = keepSelections[duplicateID] ?? Set(duplicate.occurrences.map(\.playlistID))

        if keep {
            kept.insert(playlistID)
        } else {
            guard kept.count > 1 else {
                NSSound.beep()
                return
            }

            kept.remove(playlistID)
        }

        keepSelections[duplicateID] = kept
    }

    func keepOnly(playlistID: String, duplicateID: String) {
        guard workState == .idle,
              let duplicate = duplicates.first(where: { $0.id == duplicateID }) else {
            return
        }

        var kept = Set([playlistID])
        let lockedPlaylistIDs = duplicate.occurrences
            .filter { !$0.canRemove }
            .map(\.playlistID)

        kept.formUnion(lockedPlaylistIDs)
        keepSelections[duplicateID] = kept
    }

    func resetReviewChoices() {
        guard workState == .idle else { return }

        keepSelections = Dictionary(
            uniqueKeysWithValues: duplicates.map {
                ($0.id, Set($0.occurrences.map(\.playlistID)))
            }
        )
    }

    func applyRemovals() {
        let requests = pendingRemovals
        guard !requests.isEmpty, workState == .idle else { return }

        let playlistIDs = selectedPlaylistIDs
        workState = .applying
        errorMessage = nil
        lastRemovalResult = nil
        removalProgress = RemovalProgress(
            completedRequests: 0,
            totalRequests: requests.count,
            removedEntries: 0,
            currentTrackTitle: "Preparing removals",
            currentPlaylistName: ""
        )
        statusMessage = "Removing 0 of \(requests.count)"

        Task {
            defer { workState = .idle }

            do {
                let result = try await musicAutomation.applyRemovals(requests) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        guard let self, self.workState == .applying else { return }

                        self.removalProgress = progress
                        self.statusMessage = "Removing \(progress.countText)"
                    }
                }
                lastRemovalResult = result
                statusMessage = result.failures.isEmpty
                    ? "Removed \(result.removedEntries) playlist entries"
                    : "Removed \(result.removedEntries), \(result.failures.count) failed"

                if result.removedEntries > 0 {
                    workState = .scanning

                    do {
                        let rescannedDuplicates = try await musicAutomation.scanPlaylists(withIDs: playlistIDs)
                        guard selectedPlaylistIDs == playlistIDs else { return }

                        duplicates = rescannedDuplicates
                        keepSelections = Dictionary(
                            uniqueKeysWithValues: rescannedDuplicates.map {
                                ($0.id, Set($0.occurrences.map(\.playlistID)))
                            }
                        )
                    } catch {
                        duplicates = []
                        keepSelections = [:]
                        errorMessage = "Removals were applied, but the refresh failed: \(error.localizedDescription)"
                        statusMessage = "Removals applied; rescan required"
                    }
                }
            } catch {
                duplicates = []
                keepSelections = [:]
                errorMessage = error.localizedDescription
                statusMessage = "Apply failed; rescan required"
            }
        }
    }
}
