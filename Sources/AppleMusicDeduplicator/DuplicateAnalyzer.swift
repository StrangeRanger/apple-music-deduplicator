import Foundation

enum DuplicateAnalyzer {
    enum ScanError: LocalizedError {
        case incompleteMetadata

        var errorDescription: String? {
            "Music returned incomplete song details. Please scan again."
        }
    }

    static func duplicates(
        from playlists: [PlaylistTrackSnapshot],
        loadMetadata: (_ playlistIndex: Int, _ databaseIDs: Set<Int>) throws -> [Int: TrackMetadata]
    ) throws -> [DuplicateSong] {
        var playlistIndicesByTrack: [Int: [Int]] = [:]
        var seenPlaylists = Set<String>()

        for (index, snapshot) in playlists.enumerated() {
            guard seenPlaylists.insert(snapshot.playlist.playlistID).inserted else { continue }

            // Repeats inside one playlist do not count as cross-playlist duplicates.
            for databaseID in Set(snapshot.databaseIDs) where databaseID > 0 {
                playlistIndicesByTrack[databaseID, default: []].append(index)
            }
        }

        var duplicateIDsByFirstPlaylist: [Int: Set<Int>] = [:]
        for (databaseID, indices) in playlistIndicesByTrack where indices.count > 1 {
            duplicateIDsByFirstPlaylist[indices[0], default: []].insert(databaseID)
        }

        var duplicates: [DuplicateSong] = []
        for playlistIndex in duplicateIDsByFirstPlaylist.keys.sorted() {
            let databaseIDs = duplicateIDsByFirstPlaylist[playlistIndex]!
            // Each duplicate's metadata is read once, from its first playlist.
            // The loader can release a playlist's bulk response before reading the next.
            let metadata = try loadMetadata(playlistIndex, databaseIDs)

            for databaseID in databaseIDs {
                guard let display = metadata[databaseID] else {
                    throw ScanError.incompleteMetadata
                }

                let occurrences = playlistIndicesByTrack[databaseID]!
                    .map { playlists[$0].playlist }
                    .sorted { lhs, rhs in
                        lhs.playlistName.localizedStandardCompare(rhs.playlistName) == .orderedAscending
                    }

                duplicates.append(DuplicateSong(
                    id: String(databaseID),
                    title: display.title.nonEmptyValue ?? "Untitled",
                    artist: display.artist.nonEmptyValue ?? "Unknown Artist",
                    album: display.album.nonEmptyValue ?? "",
                    time: display.time.nonEmptyValue ?? "",
                    occurrences: occurrences
                ))
            }
        }

        return duplicates.sorted { lhs, rhs in
            lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    static func removalRequests(
        duplicates: [DuplicateSong],
        keepSelections: [String: Set<String>]
    ) -> [RemovalRequest] {
        duplicates.flatMap { duplicate -> [RemovalRequest] in
            let keptPlaylists = keepSelections[duplicate.id] ?? Set(duplicate.occurrences.map(\.playlistID))

            return duplicate.occurrences.compactMap { occurrence in
                guard !keptPlaylists.contains(occurrence.playlistID), occurrence.canRemove else {
                    return nil
                }

                return RemovalRequest(
                    trackKey: duplicate.id,
                    playlistID: occurrence.playlistID,
                    trackTitle: duplicate.title,
                    playlistName: occurrence.playlistName
                )
            }
        }
    }
}

private extension String {
    var nonEmptyValue: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
