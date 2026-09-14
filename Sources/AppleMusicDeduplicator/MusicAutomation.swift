import Foundation

protocol MusicPlayback: Sendable {
    func play(_ song: DuplicateSong) async throws
    func pause() async throws
}

protocol MusicLibrary: MusicPlayback {
    func loadPlaylists() async throws -> [PlaylistSummary]
    func scanPlaylists(withIDs playlistIDs: Set<String>) async throws -> [DuplicateSong]
    func applyRemovals(
        _ requests: [RemovalRequest],
        progressHandler: @escaping @Sendable (RemovalProgress) -> Void
    ) async throws -> RemovalResult
}

enum MusicAutomationError: LocalizedError {
    case musicUnavailable
    case musicLaunchFailed(String)
    case permissionDenied
    case appleEventFailed(String)
    case objectNotFound
    case playlistUnavailable(String)
    case invalidTrackData(String)
    case playlistChanged(String)
    case trackUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .musicUnavailable:
            "Music is not available on this Mac."
        case .musicLaunchFailed(let message):
            "Could not open Music: \(message)"
        case .permissionDenied:
            "Music access was denied. Enable this app under System Settings > Privacy & Security > Automation, then try again."
        case .appleEventFailed(let message):
            message
        case .objectNotFound:
            "Music could not find the requested item. Please scan again."
        case .playlistUnavailable(let playlistName):
            "Could not find playlist \"\(playlistName)\"."
        case .invalidTrackData(let playlistName):
            "Music returned incomplete track data for \"\(playlistName)\". Please scan again."
        case .playlistChanged(let playlistName):
            "Playlist \"\(playlistName)\" changed while scanning. Please scan again."
        case .trackUnavailable(let title):
            "Could not find \"\(title)\" in Music. It may have been removed from your library. Please scan again."
        }
    }
}

final class MusicAutomation: MusicLibrary {
    private let prepareConnection: @Sendable () async throws -> Void
    private let makeConnection: @Sendable () throws -> MusicAppleEvents

    init() {
        self.prepareConnection = MusicAppleEvents.prepareApplication
        self.makeConnection = MusicAppleEvents.live
    }

    init(
        prepareConnection: @escaping @Sendable () async throws -> Void = {},
        makeConnection: @escaping @Sendable () throws -> MusicAppleEvents
    ) {
        self.prepareConnection = prepareConnection
        self.makeConnection = makeConnection
    }

    func play(_ song: DuplicateSong) async throws {
        guard let databaseID = Int32(song.id), databaseID > 0 else {
            throw MusicAutomationError.trackUnavailable(song.title)
        }
        try await prepareConnection()
        try await Self.runOffMain { [makeConnection] in
            try makeConnection().play(databaseID: databaseID, title: song.title)
        }
    }

    func pause() async throws {
        try await prepareConnection()
        try await Self.runOffMain { [makeConnection] in
            try makeConnection().pause()
        }
    }

    func loadPlaylists() async throws -> [PlaylistSummary] {
        try await prepareConnection()
        return try await Self.runOffMain { [makeConnection] in
            let music = try makeConnection()
            return try music.userPlaylists().map { playlist in
                try PlaylistSummary(
                    id: playlist.id, name: playlist.name, sourceName: playlist.sourceName,
                    trackCount: music.trackCount(in: playlist),
                    canRemoveTracks: playlist.canRemove, kindLabel: playlist.kindLabel
                )
            }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    func scanPlaylists(withIDs playlistIDs: Set<String>) async throws -> [DuplicateSong] {
        guard playlistIDs.count >= 2 else { return [] }
        try await prepareConnection()
        return try await Self.runOffMain { [makeConnection] in
            let music = try makeConnection()
            let selected = try music.userPlaylists(withIDs: playlistIDs)
            if let missingID = playlistIDs.subtracting(selected.map(\.id)).sorted().first {
                throw MusicAutomationError.playlistUnavailable(missingID)
            }
            let snapshots = try selected.map {
                try PlaylistTrackSnapshot(playlist: $0.occurrence, databaseIDs: music.databaseIDs(in: $0))
            }
            return try DuplicateAnalyzer.duplicates(from: snapshots) { index, requestedIDs in
                try autoreleasepool {
                    let playlist = selected[index]
                    // Read complete columns, once per playlist that describes duplicates.
                    let titles = try music.trackColumn(MusicCode.name, in: playlist).map { $0.stringValue ?? "" }
                    let artists = try music.trackColumn(MusicCode.artist, in: playlist).map { $0.stringValue ?? "" }
                    let albums = try music.trackColumn(MusicCode.album, in: playlist).map { $0.stringValue ?? "" }
                    let times = try music.trackColumn(MusicCode.time, in: playlist).map { $0.stringValue ?? "" }
                    return try Self.trackMetadata(
                        for: snapshots[index], requestedIDs: requestedIDs,
                        currentIDs: music.databaseIDs(in: playlist),
                        titles: titles, artists: artists, albums: albums, times: times
                    )
                }
            }
        }
    }

    func applyRemovals(
        _ requests: [RemovalRequest],
        progressHandler: @escaping @Sendable (RemovalProgress) -> Void
    ) async throws -> RemovalResult {
        guard !requests.isEmpty else {
            return RemovalResult(requestedCount: 0, removedEntries: 0, failures: [])
        }
        try await prepareConnection()
        return try await Self.runOffMain { [makeConnection] in
            let music = try makeConnection()
            var playlistsByID: [String: MusicAppleEvents.Playlist] = [:]
            for playlist in try music.userPlaylists(withIDs: Set(requests.map(\.playlistID))) {
                playlistsByID[playlist.id] = playlist
            }
            var removedEntries = 0
            var failures: [RemovalFailure] = []
            var completedRequests = 0

            func finish(_ request: RemovalRequest, failure: String? = nil) {
                if let failure {
                    failures.append(RemovalFailure(
                        trackKey: request.trackKey, playlistID: request.playlistID,
                        trackTitle: request.trackTitle, playlistName: request.playlistName, message: failure
                    ))
                }
                completedRequests += 1
                Self.reportProgress(
                    completedRequests: completedRequests, totalRequests: requests.count,
                    removedEntries: removedEntries, request: request, progressHandler: progressHandler
                )
            }

            for batch in Self.removalBatches(from: requests) {
                guard let first = batch.first else { continue }
                guard let playlist = playlistsByID[first.playlistID] else {
                    for request in batch {
                        finish(request, failure: MusicAutomationError.playlistUnavailable(request.playlistName).localizedDescription)
                    }
                    continue
                }
                guard playlist.canRemove else {
                    for request in batch { finish(request, failure: "This playlist cannot be edited by Music automation.") }
                    continue
                }
                var tracksByKey = Dictionary(grouping: try music.entries(in: playlist)) { String($0.databaseID) }
                for request in batch {
                    guard let matches = tracksByKey.removeValue(forKey: request.trackKey), !matches.isEmpty else {
                        finish(request, failure: "Track was not found in this playlist.")
                        continue
                    }
                    do {
                        for entry in matches.reversed() {
                            try music.delete(entry, from: playlist)
                            removedEntries += 1
                        }
                        finish(request)
                    } catch {
                        // Count only acknowledged deletions, including partial success
                        // when Music rejects a later occurrence of the same song.
                        finish(request, failure: error.localizedDescription)
                    }
                }
            }
            return RemovalResult(requestedCount: requests.count, removedEntries: removedEntries, failures: failures)
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

    static func trackMetadata(
        for snapshot: PlaylistTrackSnapshot,
        requestedIDs: Set<Int>,
        currentIDs: [Int],
        titles: [Any],
        artists: [Any],
        albums: [Any],
        times: [Any]
    ) throws -> [Int: TrackMetadata] {
        // Separate bulk reads must still refer to the same playlist order. Never
        // zip truncated columns or attach a song's details to a different ID.
        guard currentIDs == snapshot.databaseIDs else {
            throw MusicAutomationError.playlistChanged(snapshot.playlist.playlistName)
        }
        let count = snapshot.databaseIDs.count
        guard titles.count == count, artists.count == count,
              albums.count == count, times.count == count else {
            throw MusicAutomationError.invalidTrackData(snapshot.playlist.playlistName)
        }

        var metadata: [Int: TrackMetadata] = [:]
        metadata.reserveCapacity(requestedIDs.count)
        for (index, databaseID) in snapshot.databaseIDs.enumerated()
        where requestedIDs.contains(databaseID) && metadata[databaseID] == nil {
            metadata[databaseID] = TrackMetadata(
                title: titles[index] as? String ?? "",
                artist: artists[index] as? String ?? "",
                album: albums[index] as? String ?? "",
                time: times[index] as? String ?? ""
            )
        }
        return metadata
    }

}
