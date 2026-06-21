import Foundation
import ScriptingBridge

enum MusicAutomationError: LocalizedError {
    case musicUnavailable
    case permissionDenied
    case appleEventFailed(String)
    case playlistUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .musicUnavailable:
            "Music is not available on this Mac."
        case .permissionDenied:
            "Music access was denied. Enable this app under System Settings > Privacy & Security > Automation, then try again."
        case .appleEventFailed(let message):
            message
        case .playlistUnavailable(let playlistName):
            "Could not find playlist \"\(playlistName)\"."
        }
    }
}

final class MusicAutomation: Sendable {
    func loadPlaylists() async throws -> [PlaylistSummary] {
        try await Self.runOffMain {
            let music = try Self.musicApplication()
            music.fixedIndexing = true

            let summaries = Self.allUserPlaylists(in: music).compactMap { playlistContext -> PlaylistSummary? in
                let playlist = playlistContext.playlist
                guard let playlistID = playlist.persistentID.nonEmptyValue,
                      playlist.specialKind != MusicESpKFolder else {
                    return nil
                }

                return PlaylistSummary(
                    id: playlistID,
                    name: playlist.name.nonEmptyValue ?? "Untitled Playlist",
                    sourceName: playlistContext.sourceName,
                    trackCount: playlist.tracks().count,
                    canRemoveTracks: Self.canRemoveTracks(from: playlist),
                    kindLabel: Self.kindLabel(for: playlist)
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            try Self.throwLastErrorIfNeeded(from: music)
            return summaries
        }
    }

    func scanPlaylists(withIDs playlistIDs: Set<String>) async throws -> [DuplicateSong] {
        try await Self.runOffMain {
            let music = try Self.musicApplication()
            music.fixedIndexing = true

            let selectedPlaylists = Self.allUserPlaylists(in: music).filter {
                guard let playlistID = $0.playlist.persistentID.nonEmptyValue else {
                    return false
                }

                return playlistIDs.contains(playlistID)
            }

            let occurrences = selectedPlaylists.flatMap { context in
                Self.trackOccurrences(in: context.playlist, sourceName: context.sourceName)
            }

            try Self.throwLastErrorIfNeeded(from: music)
            return DuplicateAnalyzer.duplicates(from: occurrences)
        }
    }

    func applyRemovals(
        _ requests: [RemovalRequest],
        progressHandler: @escaping @Sendable (RemovalProgress) -> Void
    ) async throws -> RemovalResult {
        try await Self.runOffMain {
            let music = try Self.musicApplication()
            music.fixedIndexing = true

            let playlistPairs: [(String, MusicUserPlaylist)] = Self.allUserPlaylists(in: music).compactMap {
                guard let playlistID = $0.playlist.persistentID.nonEmptyValue else {
                    return nil
                }

                return (playlistID, $0.playlist)
            }
            let playlistsByID = Dictionary(uniqueKeysWithValues: playlistPairs)

            var removedEntries = 0
            var failures: [RemovalFailure] = []
            var completedRequests = 0

            func recordFailure(_ request: RemovalRequest, message: String) {
                failures.append(
                    RemovalFailure(
                        trackKey: request.trackKey,
                        playlistID: request.playlistID,
                        trackTitle: request.trackTitle,
                        playlistName: request.playlistName,
                        message: message
                    )
                )
                completedRequests += 1
                Self.reportProgress(
                    completedRequests: completedRequests,
                    totalRequests: requests.count,
                    removedEntries: removedEntries,
                    request: request,
                    progressHandler: progressHandler
                )
            }

            for batch in Self.removalBatches(from: requests) {
                guard let firstRequest = batch.first else { continue }

                guard let playlist = playlistsByID[firstRequest.playlistID] else {
                    for request in batch {
                        recordFailure(
                            request,
                            message: MusicAutomationError.playlistUnavailable(request.playlistName)
                                .localizedDescription
                        )
                    }
                    continue
                }

                guard Self.canRemoveTracks(from: playlist) else {
                    for request in batch {
                        recordFailure(
                            request,
                            message: "This playlist cannot be edited by Music automation."
                        )
                    }
                    continue
                }

                var tracksByKey = Dictionary(grouping: Self.tracks(in: playlist)) {
                    String($0.databaseID)
                }

                for request in batch {
                    guard let matchingTracks = tracksByKey.removeValue(forKey: request.trackKey),
                          !matchingTracks.isEmpty else {
                        recordFailure(request, message: "Track was not found in this playlist.")
                        continue
                    }

                    for track in matchingTracks.reversed() {
                        track.delete()
                        removedEntries += 1
                    }

                    completedRequests += 1
                    Self.reportProgress(
                        completedRequests: completedRequests,
                        totalRequests: requests.count,
                        removedEntries: removedEntries,
                        request: request,
                        progressHandler: progressHandler
                    )
                }
            }

            try Self.throwLastErrorIfNeeded(from: music)

            return RemovalResult(
                requestedCount: requests.count,
                removedEntries: removedEntries,
                failures: failures
            )
        }
    }

    static func removalBatches(from requests: [RemovalRequest]) -> [[RemovalRequest]] {
        var batchIndexByPlaylistID: [String: Int] = [:]
        var batches: [[RemovalRequest]] = []

        for request in requests {
            if let batchIndex = batchIndexByPlaylistID[request.playlistID] {
                batches[batchIndex].append(request)
            } else {
                batchIndexByPlaylistID[request.playlistID] = batches.count
                batches.append([request])
            }
        }

        return batches
    }

    private struct PlaylistContext {
        let playlist: MusicUserPlaylist
        let sourceName: String
    }

    private static func runOffMain<Value: Sendable>(
        _ operation: @escaping @Sendable () throws -> Value
    ) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try operation())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func reportProgress(
        completedRequests: Int,
        totalRequests: Int,
        removedEntries: Int,
        request: RemovalRequest,
        progressHandler: @Sendable (RemovalProgress) -> Void
    ) {
        progressHandler(
            RemovalProgress(
                completedRequests: completedRequests,
                totalRequests: totalRequests,
                removedEntries: removedEntries,
                currentTrackTitle: request.trackTitle,
                currentPlaylistName: request.playlistName
            )
        )
    }

    private static func musicApplication() throws -> MusicApplication {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") != nil else {
            throw MusicAutomationError.musicUnavailable
        }

        guard let music = MusicApplication(bundleIdentifier: "com.apple.Music") else {
            throw MusicAutomationError.musicUnavailable
        }

        return music
    }

    private static func allUserPlaylists(in music: MusicApplication) -> [PlaylistContext] {
        sources(in: music)
            .filter { $0.kind == MusicESrcLibrary }
            .flatMap { source in
                let sourceName = source.name.nonEmptyValue ?? "Library"
                return userPlaylists(in: source).map {
                    PlaylistContext(playlist: $0, sourceName: sourceName)
                }
            }
    }

    private static func sources(in music: MusicApplication) -> [MusicSource] {
        (music.sources().get() as? [MusicSource]) ?? []
    }

    private static func userPlaylists(in source: MusicSource) -> [MusicUserPlaylist] {
        (source.userPlaylists().get() as? [MusicUserPlaylist]) ?? []
    }

    private static func tracks(in playlist: MusicPlaylist) -> [MusicTrack] {
        (playlist.tracks().get() as? [MusicTrack]) ?? []
    }

    private static func trackOccurrences(
        in playlist: MusicUserPlaylist,
        sourceName: String
    ) -> [ScannedTrackOccurrence] {
        guard let playlistID = playlist.persistentID.nonEmptyValue else {
            return []
        }

        let playlistName = playlist.name.nonEmptyValue ?? "Untitled Playlist"
        let canRemove = canRemoveTracks(from: playlist)

        return tracks(in: playlist).compactMap { track -> ScannedTrackOccurrence? in
            let databaseID = track.databaseID
            guard databaseID > 0 else { return nil }

            return ScannedTrackOccurrence(
                trackKey: String(databaseID),
                title: track.name.nonEmptyValue ?? "Untitled",
                artist: track.artist.nonEmptyValue ?? "",
                album: track.album.nonEmptyValue ?? "",
                time: track.time.nonEmptyValue ?? "",
                playlistID: playlistID,
                playlistName: playlistName,
                canRemoveFromPlaylist: canRemove
            )
        }
    }

    private static func canRemoveTracks(from playlist: MusicUserPlaylist) -> Bool {
        playlist.specialKind == MusicESpKNone && !playlist.smart && !playlist.genius
    }

    private static func kindLabel(for playlist: MusicUserPlaylist) -> String {
        if playlist.smart {
            return "Smart"
        }

        if playlist.genius {
            return "Genius"
        }

        switch playlist.specialKind {
        case MusicESpKFolder:
            return "Folder"
        case MusicESpKNone:
            return "Playlist"
        default:
            return "System"
        }
    }

    private static func throwLastErrorIfNeeded(from music: MusicApplication) throws {
        guard let error = music.lastError() else { return }

        let nsError = error as NSError
        if nsError.domain == NSOSStatusErrorDomain && nsError.code == -1743 {
            throw MusicAutomationError.permissionDenied
        }

        throw MusicAutomationError.appleEventFailed(error.localizedDescription)
    }
}

private extension Optional where Wrapped == String {
    var nonEmptyValue: String? {
        guard let value = self else { return nil }

        let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
