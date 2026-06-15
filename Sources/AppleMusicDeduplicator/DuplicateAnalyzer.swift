import Foundation

enum DuplicateAnalyzer {
    static func duplicates(from occurrences: [ScannedTrackOccurrence]) -> [DuplicateSong] {
        let grouped = Dictionary(grouping: occurrences, by: \.trackKey)

        return grouped.compactMap { trackKey, trackOccurrences in
            let uniqueOccurrences = uniquePlaylistOccurrences(from: trackOccurrences)
            guard uniqueOccurrences.count > 1 else { return nil }

            let display = trackOccurrences.first
            return DuplicateSong(
                id: trackKey,
                title: display?.title.nonEmptyValue ?? "Untitled",
                artist: display?.artist.nonEmptyValue ?? "Unknown Artist",
                album: display?.album.nonEmptyValue ?? "",
                time: display?.time.nonEmptyValue ?? "",
                occurrences: uniqueOccurrences
            )
        }
        .sorted { lhs, rhs in
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

    private static func uniquePlaylistOccurrences(
        from occurrences: [ScannedTrackOccurrence]
    ) -> [PlaylistOccurrence] {
        var seen = Set<String>()

        return occurrences.compactMap { occurrence in
            guard seen.insert(occurrence.playlistID).inserted else { return nil }

            return PlaylistOccurrence(
                playlistID: occurrence.playlistID,
                playlistName: occurrence.playlistName,
                canRemove: occurrence.canRemoveFromPlaylist
            )
        }
        .sorted { lhs, rhs in
            lhs.playlistName.localizedStandardCompare(rhs.playlistName) == .orderedAscending
        }
    }
}

private extension String {
    var nonEmptyValue: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
