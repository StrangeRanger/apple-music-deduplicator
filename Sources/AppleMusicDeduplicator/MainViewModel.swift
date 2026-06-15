import AppKit
import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    enum WorkState: Equatable {
        case idle
        case loading
        case scanning
        case applying
    }

    @Published private(set) var playlists: [PlaylistSummary] = []
    @Published var selectedPlaylistIDs = Set<String>()
    @Published private(set) var duplicates: [DuplicateSong] = []
    @Published private(set) var keepSelections: [String: Set<String>] = [:]
    @Published private(set) var workState: WorkState = .idle
    @Published var filterText = ""
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    @Published var lastRemovalResult: RemovalResult?
    @Published private(set) var removalProgress: RemovalProgress?

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

    var canApplyRemovals: Bool {
        !pendingRemovals.isEmpty && workState == .idle
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

        workState = .scanning
        errorMessage = nil
        lastRemovalResult = nil
        removalProgress = nil
        statusMessage = "Scanning selected playlists"

        Task {
            do {
                let scannedDuplicates = try await musicAutomation.scanPlaylists(withIDs: selectedPlaylistIDs)
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

            workState = .idle
        }
    }

    func setKeep(_ keep: Bool, duplicateID: String, playlistID: String) {
        guard let duplicate = duplicates.first(where: { $0.id == duplicateID }),
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
        guard let duplicate = duplicates.first(where: { $0.id == duplicateID }) else { return }

        var kept = Set([playlistID])
        let lockedPlaylistIDs = duplicate.occurrences
            .filter { !$0.canRemove }
            .map(\.playlistID)

        kept.formUnion(lockedPlaylistIDs)
        keepSelections[duplicateID] = kept
    }

    func resetReviewChoices() {
        keepSelections = Dictionary(
            uniqueKeysWithValues: duplicates.map {
                ($0.id, Set($0.occurrences.map(\.playlistID)))
            }
        )
    }

    func applyRemovals() {
        let requests = pendingRemovals
        guard !requests.isEmpty, workState == .idle else { return }

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
            do {
                let result = try await musicAutomation.applyRemovals(requests) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.removalProgress = progress
                        self?.statusMessage = "Removing \(progress.countText)"
                    }
                }
                lastRemovalResult = result
                statusMessage = result.failures.isEmpty
                    ? "Removed \(result.removedEntries) playlist entries"
                    : "Removed \(result.removedEntries), \(result.failures.count) failed"

                if result.removedEntries > 0 {
                    let rescannedDuplicates = try await musicAutomation.scanPlaylists(withIDs: selectedPlaylistIDs)
                    duplicates = rescannedDuplicates
                    keepSelections = Dictionary(
                        uniqueKeysWithValues: rescannedDuplicates.map {
                            ($0.id, Set($0.occurrences.map(\.playlistID)))
                        }
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Apply failed"
            }

            workState = .idle
        }
    }
}
