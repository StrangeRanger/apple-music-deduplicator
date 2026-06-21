import XCTest
@testable import AppleMusicDeduplicator

final class DuplicateAnalyzerTests: XCTestCase {
    func testFindsTrackAcrossMultiplePlaylists() {
        let occurrences = [
            occurrence(trackKey: "42", playlistID: "a", playlistName: "Inbox"),
            occurrence(trackKey: "42", playlistID: "b", playlistName: "QC"),
            occurrence(trackKey: "99", playlistID: "a", playlistName: "Inbox")
        ]

        let duplicates = DuplicateAnalyzer.duplicates(from: occurrences)

        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates.first?.id, "42")
        XCTAssertEqual(duplicates.first?.occurrences.map(\.playlistID), ["a", "b"])
    }

    func testIgnoresRepeatedTrackWithinSinglePlaylist() {
        let occurrences = [
            occurrence(trackKey: "42", playlistID: "a", playlistName: "Inbox"),
            occurrence(trackKey: "42", playlistID: "a", playlistName: "Inbox")
        ]

        XCTAssertTrue(DuplicateAnalyzer.duplicates(from: occurrences).isEmpty)
    }

    func testRemovalRequestsSkipKeptAndLockedPlaylists() {
        let duplicate = DuplicateSong(
            id: "42",
            title: "Song",
            artist: "Artist",
            album: "Album",
            time: "3:11",
            occurrences: [
                PlaylistOccurrence(playlistID: "a", playlistName: "Keep", canRemove: true),
                PlaylistOccurrence(playlistID: "b", playlistName: "Remove", canRemove: true),
                PlaylistOccurrence(playlistID: "c", playlistName: "Smart", canRemove: false)
            ]
        )

        let requests = DuplicateAnalyzer.removalRequests(
            duplicates: [duplicate],
            keepSelections: ["42": Set(["a"])]
        )

        XCTAssertEqual(requests.map(\.playlistID), ["b"])
    }

    func testRemovalBatchesGroupByPlaylistAndPreserveFirstSeenOrder() {
        let requests = [
            removalRequest(trackKey: "1", playlistID: "b"),
            removalRequest(trackKey: "2", playlistID: "a"),
            removalRequest(trackKey: "3", playlistID: "b")
        ]

        let batches = MusicAutomation.removalBatches(from: requests)

        XCTAssertEqual(batches.map { $0.map(\.playlistID) }, [["b", "b"], ["a"]])
        XCTAssertEqual(batches.map { $0.map(\.trackKey) }, [["1", "3"], ["2"]])
    }

    private func occurrence(
        trackKey: String,
        playlistID: String,
        playlistName: String
    ) -> ScannedTrackOccurrence {
        ScannedTrackOccurrence(
            trackKey: trackKey,
            title: "Song",
            artist: "Artist",
            album: "Album",
            time: "3:11",
            playlistID: playlistID,
            playlistName: playlistName,
            canRemoveFromPlaylist: true
        )
    }

    private func removalRequest(trackKey: String, playlistID: String) -> RemovalRequest {
        RemovalRequest(
            trackKey: trackKey,
            playlistID: playlistID,
            trackTitle: "Song \(trackKey)",
            playlistName: "Playlist \(playlistID)"
        )
    }
}
