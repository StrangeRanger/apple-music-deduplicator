import XCTest
@testable import AppleMusicDeduplicator

final class DuplicateAnalyzerTests: XCTestCase {
    func testFindsTrackAcrossMultiplePlaylists() throws {
        let playlists = [
            snapshot(ids: [42, 99], playlistID: "a", playlistName: "Inbox"),
            snapshot(ids: [42], playlistID: "b", playlistName: "QC")
        ]

        let duplicates = try DuplicateAnalyzer.duplicates(from: playlists, loadMetadata: metadata)

        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates.first?.id, "42")
        XCTAssertEqual(duplicates.first?.occurrences.map(\.playlistID), ["a", "b"])
    }

    func testIgnoresRepeatedTrackWithinSinglePlaylist() throws {
        let playlists = [
            snapshot(ids: [42, 42], playlistID: "a", playlistName: "Inbox"),
            snapshot(ids: [99], playlistID: "b", playlistName: "QC")
        ]

        let duplicates = try DuplicateAnalyzer.duplicates(from: playlists) { _, _ in
            XCTFail("A scan without duplicates should not load song details")
            return [:]
        }
        XCTAssertTrue(duplicates.isEmpty)
    }

    func testLoadsMetadataOncePerFirstPlaylistAndOnlyForDuplicates() throws {
        let playlists = [
            snapshot(ids: [42, 42, 43, 99, 0, -1], playlistID: "a", playlistName: "Zebra"),
            snapshot(ids: [42, 43, 50, 0, -1], playlistID: "b", playlistName: "Alpha"),
            snapshot(ids: [42, 50], playlistID: "c", playlistName: "Middle", canRemove: false)
        ]
        var requests: [Int: Set<Int>] = [:]
        let duplicates = try DuplicateAnalyzer.duplicates(from: playlists) { index, ids in
            XCTAssertNil(requests.updateValue(ids, forKey: index))
            return metadata(playlistIndex: index, databaseIDs: ids)
        }

        XCTAssertEqual(requests, [0: [42, 43], 1: [50]])
        XCTAssertEqual(duplicates.map(\.id), ["42", "43", "50"])
        XCTAssertEqual(duplicates.first?.occurrences.map(\.playlistID), ["b", "c", "a"])
        XCTAssertEqual(duplicates.first?.occurrences.map(\.canRemove), [true, false, true])
    }

    func testEmptyAndRepeatedPlaylistInputsDoNotLoadMetadata() throws {
        let playlist = snapshot(ids: [42], playlistID: "a", playlistName: "Inbox")
        for input in [[], [playlist], [playlist, playlist]] {
            let duplicates = try DuplicateAnalyzer.duplicates(from: input) { _, _ in
                XCTFail("At least two distinct playlists are required")
                return [:]
            }
            XCTAssertTrue(duplicates.isEmpty)
        }
    }

    func testMetadataDefaultsTrimmingAndNaturalSort() throws {
        let playlists = [
            snapshot(ids: [1, 2, 3], playlistID: "a", playlistName: "Playlist 10"),
            snapshot(ids: [1, 2, 3], playlistID: "b", playlistName: "Playlist 2")
        ]
        let duplicates = try DuplicateAnalyzer.duplicates(from: playlists) { _, _ in
            [
                1: TrackMetadata(title: " Song 10 ", artist: " Artist ", album: " Album ", time: " 3:11 "),
                2: TrackMetadata(title: "Song 2", artist: "", album: "", time: ""),
                3: TrackMetadata(title: " \n", artist: " \n", album: " \n", time: " \n")
            ]
        }

        XCTAssertEqual(duplicates.map(\.title), ["Song 2", "Song 10", "Untitled"])
        XCTAssertEqual(duplicates[1].artist, "Artist")
        XCTAssertEqual(duplicates[1].album, "Album")
        XCTAssertEqual(duplicates[1].time, "3:11")
        XCTAssertEqual(duplicates[2].artist, "Unknown Artist")
        XCTAssertEqual(duplicates[2].album, "")
        XCTAssertEqual(duplicates[2].time, "")
        XCTAssertEqual(duplicates[0].occurrences.map(\.playlistID), ["b", "a"])
    }

    func testMetadataFailuresDoNotReturnPartialResults() {
        let playlists = [
            snapshot(ids: [42], playlistID: "a", playlistName: "Inbox"),
            snapshot(ids: [42], playlistID: "b", playlistName: "QC")
        ]
        XCTAssertThrowsError(try DuplicateAnalyzer.duplicates(from: playlists) { _, _ in [:] })

        enum TestError: Error { case unavailable }
        XCTAssertThrowsError(try DuplicateAnalyzer.duplicates(from: playlists) { _, _ in
            throw TestError.unavailable
        }) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testLargeScanBatchesMetadataAndMatchesReferenceMemberships() throws {
        // 100,000 entries with overlapping ranges and repeated entries in each playlist.
        let playlists = (0..<20).map { index in
            snapshot(
                ids: (0..<5_000).map { index * 2_000 + $0 / 2 + 1 },
                playlistID: "\(index)", playlistName: "Playlist \(index)"
            )
        }
        var reference: [Int: Set<String>] = [:]
        for playlist in playlists {
            for id in playlist.databaseIDs {
                reference[id, default: []].insert(playlist.playlist.playlistID)
            }
        }
        reference = reference.filter { $0.value.count > 1 }

        var loadCount = 0
        var loadedIDs = Set<Int>()
        let duplicates = try DuplicateAnalyzer.duplicates(from: playlists) { index, ids in
            loadCount += 1
            XCTAssertTrue(loadedIDs.isDisjoint(with: ids))
            loadedIDs.formUnion(ids)
            return metadata(playlistIndex: index, databaseIDs: ids)
        }

        XCTAssertEqual(loadCount, 19)
        XCTAssertEqual(loadedIDs, Set(reference.keys))
        XCTAssertEqual(duplicates.count, reference.count)
        for duplicate in duplicates {
            XCTAssertEqual(Set(duplicate.occurrences.map(\.playlistID)), reference[Int(duplicate.id)!])
        }
    }

    func testBulkMetadataKeepsFirstOccurrenceAndMissingValues() throws {
        let playlist = snapshot(ids: [42, 42, 99], playlistID: "a", playlistName: "Inbox")
        let result = try MusicAutomation.trackMetadata(
            for: playlist, requestedIDs: [42], currentIDs: playlist.databaseIDs,
            titles: ["First", "Repeated", "Unique"], artists: [NSNull(), "Artist", "Artist"],
            albums: ["Album", "Album", "Album"], times: ["3:11", "3:11", "3:11"]
        )

        XCTAssertEqual(Set(result.keys), [42])
        XCTAssertEqual(result[42]?.title, "First")
        XCTAssertEqual(result[42]?.artist, "")
    }

    func testBulkMetadataRejectsChangedOrderAndTruncatedColumns() {
        let playlist = snapshot(ids: [42, 99], playlistID: "a", playlistName: "Inbox")
        XCTAssertThrowsError(try MusicAutomation.trackMetadata(
            for: playlist, requestedIDs: [42], currentIDs: [99, 42],
            titles: ["Song", "Song"], artists: ["", ""], albums: ["", ""], times: ["", ""]
        ))
        XCTAssertThrowsError(try MusicAutomation.trackMetadata(
            for: playlist, requestedIDs: [42], currentIDs: playlist.databaseIDs,
            titles: ["Song"], artists: ["", ""], albums: ["", ""], times: ["", ""]
        ))
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

    private func snapshot(
        ids: [Int],
        playlistID: String,
        playlistName: String,
        canRemove: Bool = true
    ) -> PlaylistTrackSnapshot {
        PlaylistTrackSnapshot(
            playlist: PlaylistOccurrence(
                playlistID: playlistID, playlistName: playlistName, canRemove: canRemove
            ),
            databaseIDs: ids
        )
    }

    private func metadata(playlistIndex: Int, databaseIDs: Set<Int>) -> [Int: TrackMetadata] {
        Dictionary(uniqueKeysWithValues: databaseIDs.map {
            ($0, TrackMetadata(title: "Song \($0)", artist: "Artist", album: "Album", time: "3:11"))
        })
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
