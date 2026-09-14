import XCTest
@testable import AppleMusicDeduplicator

@MainActor
final class MainViewModelTests: XCTestCase {
    func testReviewKeepsLockedOccurrencesAndResetsChoices() async throws {
        let (model, _) = try await reviewedModel()
        XCTAssertEqual(model.duplicates.count, 1)
        XCTAssertTrue(model.pendingRemovals.isEmpty)
        model.keepOnly(playlistID: "a", duplicateID: "42")
        XCTAssertEqual(model.keepSelections["42"], ["a", "locked"])
        XCTAssertEqual(model.pendingRemovals.map(\.playlistID), ["b"])
        model.setKeep(false, duplicateID: "42", playlistID: "locked")
        XCTAssertEqual(model.keepSelections["42"], ["a", "locked"])
        model.resetReviewChoices()
        XCTAssertTrue(model.pendingRemovals.isEmpty)
        model.filterText = "smart"
        XCTAssertEqual(model.filteredPlaylists.map(\.id), ["locked"])
    }

    func testSelectionAndReloadClearResultsAndPreserveExistingSelections() async throws {
        let (model, _) = try await reviewedModel()
        model.setSelected(false, playlistID: "locked")
        XCTAssertTrue(model.duplicates.isEmpty)
        XCTAssertTrue(model.keepSelections.isEmpty)
        model.scanSelectedPlaylists()
        try await waitUntil { model.workState == .idle }
        model.loadPlaylists()
        XCTAssertEqual(model.workState, .loading)
        XCTAssertTrue(model.duplicates.isEmpty)
        model.setSelected(false, playlistID: "a")
        XCTAssertEqual(model.selectedPlaylistIDs, ["a", "b"])
        try await waitUntil { model.workState == .idle }
        XCTAssertEqual(model.selectedPlaylistIDs, ["a", "b"])
    }

    func testRemovalVerifiesOriginalSelectionAndLocksReviewUntilFinished() async throws {
        let (model, library) = try await reviewedModel()
        await library.configureVerification(hold: true, fail: false)
        model.keepOnly(playlistID: "a", duplicateID: "42")
        model.applyRemovals()
        XCTAssertEqual(model.workState, .applying)
        try await waitUntil { model.workState == .verifyingRemovals }
        model.setSelected(false, playlistID: "b")
        model.setKeep(false, duplicateID: "42", playlistID: "a")
        XCTAssertEqual(model.selectedPlaylistIDs, ["a", "b", "locked"])
        XCTAssertEqual(model.keepSelections["42"], ["a", "locked"])
        await library.finishVerification()
        try await waitUntil { model.workState == .idle }
        XCTAssertTrue(model.duplicates.isEmpty)
        XCTAssertEqual(model.lastRemovalResult?.removedEntries, 1)
        XCTAssertEqual(model.statusMessage, "Verification complete — no duplicates remain")
        let scans = await library.scans
        XCTAssertEqual(scans, [["a", "b", "locked"], ["a", "b", "locked"]])
    }

    func testVerificationFailureReportsAppliedRemovalsAndRequiresRescan() async throws {
        let (model, library) = try await reviewedModel()
        await library.configureVerification(hold: false, fail: true)
        model.keepOnly(playlistID: "a", duplicateID: "42")
        model.applyRemovals()
        try await waitUntil { model.workState == .idle }
        XCTAssertEqual(model.lastRemovalResult?.removedEntries, 1)
        XCTAssertTrue(model.duplicates.isEmpty)
        XCTAssertTrue(model.keepSelections.isEmpty)
        XCTAssertEqual(model.statusMessage, "Removals applied; rescan required")
        XCTAssertTrue(model.errorMessage?.hasPrefix("Removals were applied, but the refresh failed:") == true)
    }

    func testRemovalFailureClearsStaleResultsAndAllowsRescan() async throws {
        let (model, library) = try await reviewedModel()
        await library.failRemovals()
        model.keepOnly(playlistID: "a", duplicateID: "42")
        model.applyRemovals()
        try await waitUntil { model.workState == .idle }
        XCTAssertTrue(model.duplicates.isEmpty)
        XCTAssertTrue(model.keepSelections.isEmpty)
        XCTAssertEqual(model.statusMessage, "Apply failed; rescan required")
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.canScan)
    }

    private func reviewedModel() async throws -> (MainViewModel, ReviewTestLibrary) {
        let library = ReviewTestLibrary()
        let model = MainViewModel(musicAutomation: library)
        model.loadPlaylists()
        try await waitUntil { model.workState == .idle }
        for id in ["a", "b", "locked"] { model.setSelected(true, playlistID: id) }
        model.scanSelectedPlaylists()
        XCTAssertEqual(model.workState, .scanning)
        model.setSelected(false, playlistID: "a")
        XCTAssertEqual(model.selectedPlaylistIDs.count, 3)
        try await waitUntil { model.workState == .idle }
        return (model, library)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertTrue(condition(), "The expected work state was not reached")
    }
}

private actor ReviewTestLibrary: MusicLibrary {
    private(set) var scans: [Set<String>] = []
    private var applied = false
    private var holdVerification = false
    private var verificationFails = false
    private var removalFails = false
    private var continuation: CheckedContinuation<Void, Never>?

    func play(_ song: DuplicateSong) async throws {}
    func pause() async throws {}
    func loadPlaylists() async throws -> [PlaylistSummary] {
        ["a", "b", "locked"].map {
            PlaylistSummary(id: $0, name: $0, sourceName: "Library", trackCount: 1,
                            canRemoveTracks: $0 != "locked", kindLabel: $0 == "locked" ? "Smart" : "Playlist")
        }
    }
    func scanPlaylists(withIDs playlistIDs: Set<String>) async throws -> [DuplicateSong] {
        scans.append(playlistIDs)
        if applied {
            if holdVerification { await withCheckedContinuation { continuation = $0 } }
            if verificationFails { throw MusicAutomationError.playlistChanged("Test") }
            return []
        }
        return [DuplicateSong(id: "42", title: "Song", artist: "Artist", album: "Album", time: "3:11",
                              occurrences: ["a", "b", "locked"].map {
            PlaylistOccurrence(playlistID: $0, playlistName: $0, canRemove: $0 != "locked")
        })]
    }
    func applyRemovals(_ requests: [RemovalRequest], progressHandler: @escaping @Sendable (RemovalProgress) -> Void) async throws -> RemovalResult {
        if removalFails { throw MusicAutomationError.permissionDenied }
        applied = true
        progressHandler(RemovalProgress(completedRequests: 1, totalRequests: requests.count, removedEntries: 1,
                                        currentTrackTitle: "Song", currentPlaylistName: "b"))
        return RemovalResult(requestedCount: requests.count, removedEntries: 1, failures: [])
    }
    func configureVerification(hold: Bool, fail: Bool) { holdVerification = hold; verificationFails = fail }
    func finishVerification() { continuation?.resume(); continuation = nil }
    func failRemovals() { removalFails = true }
}
