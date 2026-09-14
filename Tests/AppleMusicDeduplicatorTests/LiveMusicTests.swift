import XCTest
@testable import AppleMusicDeduplicator

@MainActor
final class LiveMusicTests: XCTestCase {
    func testLiveLoadsPlaylistsWhenMusicIsClosed() async throws {
        guard ProcessInfo.processInfo.environment["AMD_RUN_LIVE_STARTUP_TEST"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_AMD_RUN_LIVE_STARTUP_TEST=1 to test launching Music")
        }
        // The test host may have already opened Music through ContentView's
        // initial load. Quit it explicitly so this always covers a cold start.
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty {
            let music = try MusicAppleEvents.live()
            guard try music.value(MusicCode.playerState).enumCodeValue != MusicCode.playing else {
                throw XCTSkip("Pause Music before running the startup test")
            }
            try music.send(AEEventClass(kCoreEventClass), AEEventID(kAEQuitApplication))
        }
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty,
              ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty else {
            return XCTFail("Music did not quit; startup was not tested")
        }

        let playlists = try await MusicAutomation().loadPlaylists()

        XCTAssertFalse(NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty)
        XCTAssertTrue(playlists.allSatisfy { !$0.id.isEmpty })
        // The warm path must also work, using the existing Music process.
        let processID = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first?.processIdentifier
        _ = try await MusicAutomation().loadPlaylists()
        XCTAssertEqual(NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first?.processIdentifier, processID)
    }

    func testLivePlaylistScanAndRemovalPreserveLibraryTrack() async throws {
        guard ProcessInfo.processInfo.environment["AMD_RUN_LIVE_PLAYLIST_TEST"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_AMD_RUN_LIVE_PLAYLIST_TEST=1 to test temporary playlists in Music")
        }
        let music = try MusicAppleEvents.live()
        let automation = MusicAutomation()
        let originalPlaylists = try await automation.loadPlaylists()
        let originalIDs = Set(originalPlaylists.map(\.id))
        let libraryTrack = MusicAppleEvents.object(
            MusicCode.track, form: OSType(formAbsolutePosition), key: NSAppleEventDescriptor(int32: 1)
        )
        let databaseID = try MusicAppleEvents.integer(music.value(MusicCode.databaseID, of: libraryTrack))
        guard databaseID > 0 else { throw XCTSkip("A library song is required") }
        let stableLibraryTrack = try XCTUnwrap(MusicAppleEvents.list(music.get(MusicAppleEvents.tracks(matching: Int32(databaseID)))).first)
        let prefix = "AMD Swift Test \(UUID().uuidString)"
        var created: [(reference: NSAppleEventDescriptor, name: String)] = []

        // Only delete the exact playlist references created by this test, and
        // verify their unique names again before cleanup.
        func cleanup() throws {
            while let playlist = created.last {
                let name = try music.value(MusicCode.name, of: playlist.reference).stringValue
                guard name == playlist.name else {
                    throw MusicAutomationError.playlistChanged(playlist.name)
                }
                try music.send(AEEventClass(kAECoreSuite), AEEventID(kAEDelete), directObject: playlist.reference)
                created.removeLast()
            }
        }
        defer {
            do { try cleanup() }
            catch { XCTFail("Temporary playlist cleanup failed for \(prefix): \(error)") }
        }

        for suffix in ["A", "B"] {
            let name = "\(prefix) \(suffix)"
            let properties = NSAppleEventDescriptor.record()
            properties.setDescriptor(NSAppleEventDescriptor(string: name), forKeyword: MusicCode.name)
            let playlist = try music.send(
                AEEventClass(kAECoreSuite), AEEventID(kAECreateElement),
                parameters: [
                    AEKeyword(keyAEObjectClass): NSAppleEventDescriptor(typeCode: MusicCode.userPlaylist),
                    AEKeyword(keyAEPropData): properties
                ]
            )
            created.append((playlist, name))
            try music.send(
                AEEventClass(kAECoreSuite), AEEventID(kAEClone), directObject: stableLibraryTrack,
                parameters: [AEKeyword(keyAEInsertHere): playlist]
            )
        }
        // Repeated occurrences in one playlist are removed together, but still
        // represent just one cross-playlist occurrence during duplicate review.
        try music.send(
            AEEventClass(kAECoreSuite), AEEventID(kAEClone), directObject: stableLibraryTrack,
            parameters: [AEKeyword(keyAEInsertHere): created[0].reference]
        )

        let loaded = try await automation.loadPlaylists()
        let testPlaylists = loaded.filter { $0.name.hasPrefix(prefix) }
        XCTAssertEqual(testPlaylists.count, 2)
        XCTAssertTrue(testPlaylists.allSatisfy(\.canRemoveTracks))
        XCTAssertEqual(testPlaylists.map(\.trackCount), [2, 1])
        let testIDs = Set(testPlaylists.map(\.id))
        XCTAssertTrue(testIDs.isDisjoint(with: originalIDs))
        let duplicates = try await automation.scanPlaylists(withIDs: testIDs)
        let duplicate = try XCTUnwrap(duplicates.first)
        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicate.id, String(databaseID))
        XCTAssertEqual(duplicate.occurrences.count, 2)
        let removedFrom = try XCTUnwrap(testPlaylists.first)
        let request = RemovalRequest(trackKey: duplicate.id, playlistID: removedFrom.id,
                                     trackTitle: duplicate.title, playlistName: removedFrom.name)
        let result = try await automation.applyRemovals([request]) { _ in }
        XCTAssertTrue(result.failures.isEmpty, "\(result.failures.map(\.message))")
        XCTAssertEqual(result.removedEntries, 2)
        let remaining = try await automation.scanPlaylists(withIDs: testIDs)
        XCTAssertTrue(remaining.isEmpty)
        let verifiedPlaylists = try await automation.loadPlaylists().filter { testIDs.contains($0.id) }
        XCTAssertEqual(verifiedPlaylists.map(\.trackCount), [0, 1])
        XCTAssertEqual(try MusicAppleEvents.integer(music.value(MusicCode.databaseID, of: stableLibraryTrack)), databaseID)

        try cleanup()
        let finalPlaylists = try await automation.loadPlaylists()
        XCTAssertEqual(Set(finalPlaylists.map(\.id)), originalIDs)
        XCTAssertFalse(finalPlaylists.contains { $0.name.hasPrefix(prefix) })
    }
}
