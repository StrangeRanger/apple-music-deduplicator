import XCTest
@testable import AppleMusicDeduplicator

@MainActor
final class PlaybackTests: XCTestCase {
    // Opt in explicitly: this test controls real Music playback.
    func testLivePlaybackSwitchesToRequestedSongAndAdvances() async throws {
        guard ProcessInfo.processInfo.environment["AMD_RUN_LIVE_PLAYBACK_TEST"] == "1" else {
            throw XCTSkip("Set TEST_RUNNER_AMD_RUN_LIVE_PLAYBACK_TEST=1 to test real Music playback")
        }
        let music = try XCTUnwrap(MusicApplication(bundleIdentifier: "com.apple.Music"))
        let previousID = music.currentTrack?.databaseID
        let tracks = try XCTUnwrap(music.tracks())
        guard let track = (0..<min(tracks.count, 3)).compactMap({
            tracks.object(at: $0) as? MusicTrack
        }).first(where: { $0.databaseID > 0 && $0.databaseID != previousID }) else {
            throw XCTSkip("A different library song is required to verify track switching")
        }
        let trackID = track.databaseID
        defer { music.pause() }

        try await MusicAutomation().play(song(id: String(trackID)))

        // Streaming tracks may report playing while buffering at 0:00. Require
        // two advancing samples for the requested identity, not just a play state.
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(30))
        var previousPosition: Double?
        while clock.now < deadline {
            try await Task.sleep(for: .milliseconds(500))
            guard music.currentTrack?.databaseID == trackID,
                  music.playerState == MusicEPlSPlaying else {
                previousPosition = nil
                continue
            }
            let position = music.playerPosition
            if let previousPosition, position > previousPosition {
                return
            }
            previousPosition = position
        }
        XCTFail("Music did not switch to the requested song and advance playback within 30 seconds")
    }

    func testPlaysExactSongFromLockedPlaylistWithoutChangingReviewState() async {
        let playback = StubMusicPlayback()
        let model = MainViewModel(musicPlayback: playback)
        model.statusMessage = "2 duplicate songs"
        model.errorMessage = "Previous error"
        model.setSelected(true, playlistID: "locked")

        // Identical titles must still send the selected library identity.
        await model.play(song(id: "42"))
        await model.play(song(id: "99"))

        let (playedSongs, pauseCount) = await playback.history()
        XCTAssertEqual(playedSongs.map(\.id), ["42", "99"])
        XCTAssertTrue(playedSongs.allSatisfy { !$0.occurrences[0].canRemove })
        XCTAssertEqual(pauseCount, 0)
        XCTAssertEqual(model.selectedPlaylistIDs, ["locked"])
        XCTAssertEqual(model.statusMessage, "2 duplicate songs")
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.workState, .idle)
    }

    func testRejectsOverlappingActionsWhileStartingPlayback() async {
        let started = expectation(description: "Playback request started")
        let playback = StubMusicPlayback(holdPlay: true, onPlay: { started.fulfill() })
        let model = MainViewModel(musicPlayback: playback)
        model.setSelected(true, playlistID: "locked")
        let task = Task { await model.play(song(id: "42")) }
        await fulfillment(of: [started], timeout: 2)

        XCTAssertEqual(model.workState, .startingPlayback("42"))
        await model.play(song(id: "99"))
        await model.pauseMusic()
        model.setSelected(false, playlistID: "locked")
        model.loadPlaylists()

        let (playedSongs, pauseCount) = await playback.history()
        XCTAssertEqual(playedSongs.map(\.id), ["42"])
        XCTAssertEqual(pauseCount, 0)
        XCTAssertEqual(model.selectedPlaylistIDs, ["locked"])
        XCTAssertEqual(model.workState, .startingPlayback("42"))

        await playback.finishPlay()
        await task.value
        XCTAssertEqual(model.workState, .idle)
    }

    func testPlaybackFailurePreservesReviewAndAllowsRetry() async {
        let playback = StubMusicPlayback(shouldFail: true)
        let model = MainViewModel(musicPlayback: playback)
        model.statusMessage = "Review results"

        await model.play(song(id: "42"))

        XCTAssertEqual(model.workState, .idle)
        XCTAssertEqual(model.statusMessage, "Review results")
        XCTAssertEqual(model.errorMessage, "Could not play \"Song\": Playback was denied.")

        await playback.allowPlayback()
        await model.play(song(id: "42"))
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.workState, .idle)
    }

    func testPauseWorksWithoutScanResultsAndReportsFailure() async {
        let playback = StubMusicPlayback(shouldFail: true)
        let model = MainViewModel(musicPlayback: playback)

        await model.pauseMusic()
        XCTAssertEqual(model.errorMessage, "Could not pause Music: Playback was denied.")
        XCTAssertEqual(model.workState, .idle)

        await playback.allowPlayback()
        await model.pauseMusic()
        let (playedSongs, pauseCount) = await playback.history()
        XCTAssertTrue(playedSongs.isEmpty)
        XCTAssertEqual(pauseCount, 2)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.workState, .idle)
    }

    func testInvalidTrackIDsAreRejectedBeforeContactingMusic() async {
        let automation = MusicAutomation()
        for id in ["", "0", "-1", "not-an-id", "999999999999999999999999999999"] {
            do {
                try await automation.play(song(id: id))
                XCTFail("Invalid track IDs must not trigger playback")
            } catch MusicAutomationError.trackUnavailable(let title) {
                XCTAssertEqual(title, "Song")
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    private func song(id: String) -> DuplicateSong {
        DuplicateSong(
            id: id, title: "Song", artist: "Artist", album: "Album", time: "3:11",
            occurrences: [
                PlaylistOccurrence(playlistID: "locked", playlistName: "Smart", canRemove: false)
            ]
        )
    }
}

private actor StubMusicPlayback: MusicPlayback {
    private enum PlaybackError: LocalizedError {
        case denied

        var errorDescription: String? { "Playback was denied." }
    }

    private var playedSongs: [DuplicateSong] = []
    private var pauseCount = 0
    private var shouldFail: Bool
    private let holdPlay: Bool
    private let onPlay: @Sendable () -> Void
    private var playContinuation: CheckedContinuation<Void, Never>?

    init(
        shouldFail: Bool = false,
        holdPlay: Bool = false,
        onPlay: @escaping @Sendable () -> Void = {}
    ) {
        self.shouldFail = shouldFail
        self.holdPlay = holdPlay
        self.onPlay = onPlay
    }

    func play(_ song: DuplicateSong) async throws {
        playedSongs.append(song)
        if holdPlay {
            await withCheckedContinuation {
                playContinuation = $0
                onPlay()
            }
        } else {
            onPlay()
        }
        if shouldFail { throw PlaybackError.denied }
    }

    func pause() async throws {
        pauseCount += 1
        if shouldFail { throw PlaybackError.denied }
    }

    func finishPlay() {
        playContinuation?.resume()
        playContinuation = nil
    }

    func allowPlayback() { shouldFail = false }

    func history() -> ([DuplicateSong], Int) { (playedSongs, pauseCount) }
}
