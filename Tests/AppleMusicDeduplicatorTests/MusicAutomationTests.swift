import XCTest
@testable import AppleMusicDeduplicator

@MainActor
final class MusicAutomationTests: XCTestCase {
    func testLoadsCountsTypesAndNaturalOrderWithoutFoldersOrRemoteSources() async throws {
        let server = MusicTestServer()
        let playlists = try await server.automation.loadPlaylists()
        XCTAssertEqual(playlists.map(\.id), ["genius", "b", "a", "smart", "system"])
        XCTAssertEqual(playlists.map(\.trackCount), [0, 2, 3, 1, 0])
        XCTAssertEqual(playlists.map(\.canRemoveTracks), [false, true, true, false, false])
        XCTAssertEqual(playlists.map(\.kindLabel), ["Genius", "Playlist", "Playlist", "Smart", "System"])
        XCTAssertTrue(playlists.allSatisfy { $0.sourceName == "Library" })
        XCTAssertFalse(server.snapshot().events.contains { $0.eventID == kAESetData })
    }

    func testScanUsesBulkIDsAndLoadsDetailsOnlyForDuplicatePlaylist() async throws {
        let server = MusicTestServer()
        let duplicates = try await server.automation.scanPlaylists(withIDs: ["a", "b", "smart"])
        XCTAssertEqual(duplicates.map(\.id), ["42"])
        XCTAssertEqual(duplicates.first?.title, "Song 42")
        XCTAssertEqual(duplicates.first?.occurrences.map(\.playlistID), ["b", "a", "smart"])
        XCTAssertEqual(duplicates.first?.occurrences.map(\.canRemove), [true, true, false])
        let columns = server.snapshot().events.filter { $0.isColumn }
        XCTAssertEqual(columns.filter { $0.property == MusicCode.databaseID }.count, 4)
        XCTAssertEqual(columns.filter { $0.property == MusicCode.name }.map(\.playlist), ["a"])
        XCTAssertEqual(columns.filter { $0.property == MusicCode.artist }.count, 1)
        XCTAssertEqual(columns.filter { $0.property == MusicCode.album }.count, 1)
        XCTAssertEqual(columns.filter { $0.property == MusicCode.time }.count, 1)
    }

    func testNoDuplicatesDoesNotFetchMetadata() async throws {
        let server = MusicTestServer()
        let duplicates = try await server.automation.scanPlaylists(withIDs: ["genius", "system"])
        XCTAssertTrue(duplicates.isEmpty)
        XCTAssertFalse(server.snapshot().events.contains { $0.isColumn && $0.property == MusicCode.name })
    }

    func testEmptyPlaylistColumnErrorsAreVerifiedWithTrackCount() async throws {
        let server = MusicTestServer()
        server.configure { $0.missingColumns = true }
        let duplicates = try await server.automation.scanPlaylists(withIDs: ["genius", "system"])
        XCTAssertTrue(duplicates.isEmpty)
        XCTAssertEqual(server.snapshot().events.filter { $0.eventID == kAECountElements }.count, 2)
        do {
            _ = try await server.automation.scanPlaylists(withIDs: ["a", "b"])
            XCTFail("A missing column from a nonempty playlist must fail")
        } catch MusicAutomationError.playlistChanged { }
    }

    func testScanRejectsMissingPlaylistAndChangingOrTruncatedMetadata() async {
        for mode in ["missing", "changed", "truncated"] {
            let server = MusicTestServer()
            server.configure { $0.metadataMode = mode }
            do {
                _ = try await server.automation.scanPlaylists(withIDs: mode == "missing" ? ["a", "gone"] : ["a", "b"])
                XCTFail("Must not return partial or mismatched results: \(mode)")
            } catch {
                XCTAssertTrue(error is MusicAutomationError)
            }
        }
    }

    func testRemovalDeletesEveryOccurrenceOnlyFromRequestedEditablePlaylist() async throws {
        let server = MusicTestServer()
        let progress = ProgressRecorder()
        let requests = [request("42", "a"), request("99", "a"), request("42", "smart"), request("42", "gone")]
        let result = try await server.automation.applyRemovals(requests, progressHandler: progress.record)
        XCTAssertEqual(result.requestedCount, 4)
        XCTAssertEqual(result.removedEntries, 3)
        XCTAssertEqual(result.failures.map(\.playlistID), ["smart", "gone"])
        let state = server.snapshot()
        XCTAssertEqual(state.entries["a"], [])
        XCTAssertEqual(state.entries["b"]?.map(\.databaseID), [42, 100])
        XCTAssertEqual(state.entries["smart"]?.map(\.databaseID), [42])
        let deletions = state.events.filter { $0.eventID == kAEDelete }
        XCTAssertEqual(deletions.map(\.playlist), ["a", "a", "a"])
        XCTAssertEqual(deletions.map(\.objectID), [102, 101, 103])
        XCTAssertEqual(state.events.filter { $0.isColumn && $0.property == MusicCode.objectID }.count, 1)
        XCTAssertEqual(progress.values.map(\.completedRequests), [1, 2, 3, 4])
        XCTAssertEqual(progress.values.last?.removedEntries, 3)
        XCTAssertEqual(progress.values.last?.fractionCompleted, 1)
        let remaining = try await server.automation.scanPlaylists(withIDs: ["a", "b"])
        XCTAssertTrue(remaining.isEmpty)
    }

    func testFailedDeletionCountsOnlyAcknowledgedEntriesAndContinues() async throws {
        let server = MusicTestServer()
        server.configure { $0.failedObjectIDs = [101] }
        let result = try await server.automation.applyRemovals([request("42", "a"), request("100", "b")]) { _ in }
        XCTAssertEqual(result.removedEntries, 2)
        XCTAssertEqual(result.failures.count, 1)
        XCTAssertEqual(result.failures.first?.trackKey, "42")
        XCTAssertEqual(server.snapshot().entries["a"]?.map(\.objectID), [101, 103])
        XCTAssertEqual(server.snapshot().entries["b"]?.map(\.databaseID), [42])
    }

    func testPlaybackResolvesDatabaseIDAndSendsExplicitTrackAndOnce() async throws {
        let server = MusicTestServer()
        try await server.automation.play(DuplicateSong(id: "42", title: "Same title", artist: "", album: "", time: "", occurrences: []))
        try await server.automation.pause()
        let events = server.snapshot().events
        XCTAssertEqual(events.map(\.eventID), [AEEventID(kAEGetData), MusicCode.play, MusicCode.pause])
        XCTAssertEqual(events[0].filterID, 42)
        XCTAssertEqual(events[1].objectID, 101)
        XCTAssertEqual(events[1].playlist, "a")
        XCTAssertTrue(events[1].once)
    }

    func testUnavailableSongDoesNotSendPlay() async {
        let server = MusicTestServer()
        do {
            try await server.automation.play(DuplicateSong(id: "999", title: "Missing", artist: "", album: "", time: "", occurrences: []))
            XCTFail("Missing tracks should fail")
        } catch MusicAutomationError.trackUnavailable(let title) {
            XCTAssertEqual(title, "Missing")
        } catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertFalse(server.snapshot().events.contains { $0.eventID == MusicCode.play })
    }

    func testEmptyOperationsDoNotConnectToMusic() async throws {
        let automation = MusicAutomation { XCTFail("No connection expected"); throw MusicAutomationError.musicUnavailable }
        let duplicates = try await automation.scanPlaylists(withIDs: ["a"])
        let result = try await automation.applyRemovals([]) { _ in XCTFail("No progress expected") }
        XCTAssertTrue(duplicates.isEmpty)
        XCTAssertEqual(result.removedEntries, 0)
    }

    func testTransportAndReplyPermissionErrorsAreReported() {
        let clients = [
            MusicAppleEvents { _ in throw NSError(domain: NSOSStatusErrorDomain, code: -1743) },
            MusicAppleEvents { _ in MusicTestServer.reply(error: -1743) }
        ]
        for client in clients {
            XCTAssertThrowsError(try client.pause()) { error in
                guard case MusicAutomationError.permissionDenied = error else {
                    return XCTFail("Expected permission guidance, got \(error)")
                }
            }
        }
        let client = MusicAppleEvents { _ in MusicTestServer.reply(error: -10000) }
        XCTAssertThrowsError(try client.pause())
    }

    func testMalformedIDsAndListsAreRejected() {
        XCTAssertThrowsError(try MusicAppleEvents.list(.null()))
        XCTAssertThrowsError(try MusicAppleEvents.integer(NSAppleEventDescriptor(string: "not an ID")))
        XCTAssertEqual(try MusicAppleEvents.list(MusicTestServer.list([])).count, 0)
    }

    func testBulkElementSpecifierUsesAbsoluteOrdinalRatherThanEnum() {
        let sources = MusicAppleEvents.elements(MusicCode.source)
        let selector = sources.forKeyword(AEKeyword(keyAEKeyData))
        XCTAssertEqual(selector?.descriptorType, DescType(typeAbsoluteOrdinal))
        XCTAssertEqual(selector?.data, NSAppleEventDescriptor(enumCode: OSType(kAEAll)).data)
        XCTAssertEqual(sources.descriptorType, DescType(typeObjectSpecifier))
        XCTAssertEqual(sources.forKeyword(AEKeyword(keyAEDesiredClass))?.typeCodeValue, MusicCode.source)
        XCTAssertEqual(sources.forKeyword(AEKeyword(keyAEContainer))?.descriptorType, DescType(typeNull))
    }

    private func request(_ track: String, _ playlist: String) -> RemovalRequest {
        RemovalRequest(trackKey: track, playlistID: playlist, trackTitle: "Song \(track)", playlistName: playlist)
    }
}

private final class ProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [RemovalProgress] = []
    var values: [RemovalProgress] { lock.withLock { storage } }
    func record(_ progress: RemovalProgress) { lock.withLock { storage.append(progress) } }
}

/// A deterministic Music server at the Apple-event boundary. This exercises
/// production serialization, reply decoding, scanning and removal together.
private final class MusicTestServer: @unchecked Sendable {
    struct Entry: Equatable {
        let objectID: Int32
        let databaseID: Int32
    }
    struct Event {
        let eventID: AEEventID
        let property: OSType
        let playlist: String?
        let objectID: Int32?
        let isColumn: Bool
        let filterID: Int32?
        let once: Bool
    }
    struct State {
        var entries: [String: [Entry]] = [
            "a": [Entry(objectID: 101, databaseID: 42), Entry(objectID: 102, databaseID: 42), Entry(objectID: 103, databaseID: 99)],
            "b": [Entry(objectID: 201, databaseID: 42), Entry(objectID: 202, databaseID: 100)],
            "smart": [Entry(objectID: 301, databaseID: 42)], "genius": [], "system": []
        ]
        var events: [Event] = []
        var failedObjectIDs: Set<Int32> = []
        var metadataMode = ""
        var missingColumns = false
    }
    private let lock = NSLock()
    private var state = State()
    private let playlistIDs: [Int32: String] = [1: "a", 2: "b", 3: "smart", 4: "genius", 5: "system", 6: "folder"]
    var automation: MusicAutomation { MusicAutomation { MusicAppleEvents(sender: self.respond) } }
    func configure(_ update: (inout State) -> Void) { lock.withLock { update(&state) } }
    func snapshot() -> State { lock.withLock { state } }

    static func list(_ values: [NSAppleEventDescriptor]) -> NSAppleEventDescriptor {
        let list = NSAppleEventDescriptor.list()
        for (index, value) in values.enumerated() { list.insert(value, at: index + 1) }
        return list
    }
    static func reply(_ result: NSAppleEventDescriptor = .null(), error: Int32 = 0) -> NSAppleEventDescriptor {
        let reply = NSAppleEventDescriptor(eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEAnswer), targetDescriptor: nil, returnID: 0, transactionID: 0)
        reply.setParam(result, forKeyword: AEKeyword(keyDirectObject))
        reply.setParam(NSAppleEventDescriptor(int32: error), forKeyword: AEKeyword(keyErrorNumber))
        return reply
    }
    private func reference(_ code: OSType, _ id: Int32, in container: NSAppleEventDescriptor = .null()) -> NSAppleEventDescriptor {
        MusicAppleEvents.object(code, in: container, form: OSType(formUniqueID), key: NSAppleEventDescriptor(int32: id))
    }
    private func playlistID(in reference: NSAppleEventDescriptor?) -> String? {
        guard let reference else { return nil }
        if reference.forKeyword(AEKeyword(keyAEDesiredClass))?.typeCodeValue == MusicCode.userPlaylist {
            return playlistIDs[reference.forKeyword(AEKeyword(keyAEKeyData))!.int32Value]
        }
        return playlistID(in: reference.forKeyword(AEKeyword(keyAEContainer)))
    }

    private func respond(_ event: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
        try lock.withLock {
            let direct = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) ?? .null()
            let wanted = direct.forKeyword(AEKeyword(keyAEDesiredClass))?.typeCodeValue ?? 0
            let key = direct.forKeyword(AEKeyword(keyAEKeyData))
            let container = direct.forKeyword(AEKeyword(keyAEContainer)) ?? .null()
            let property = wanted == cProperty ? key?.typeCodeValue ?? 0 : 0
            let playlist = playlistID(in: direct)
            let form = direct.forKeyword(AEKeyword(keyAEKeyForm))?.enumCodeValue
            let isColumn = property != 0 && container.forKeyword(AEKeyword(keyAEKeyForm))?.enumCodeValue == OSType(formAbsolutePosition)
            let objectID = wanted == MusicCode.track && form == OSType(formUniqueID) ? key?.int32Value : nil
            let filterID = form == OSType(formTest) ? key?.forKeyword(AEKeyword(keyAEObject2))?.int32Value : nil
            state.events.append(Event(eventID: event.eventID, property: property, playlist: playlist, objectID: objectID,
                                      isColumn: isColumn, filterID: filterID, once: event.paramDescriptor(forKeyword: MusicCode.once)?.booleanValue ?? false))
            if event.eventID == kAESetData || event.eventID == MusicCode.play || event.eventID == MusicCode.pause { return Self.reply() }
            if event.eventID == kAEDelete, let playlist, let objectID {
                guard !state.failedObjectIDs.contains(objectID) else { return Self.reply(error: -10000) }
                state.entries[playlist]?.removeAll { $0.objectID == objectID }
                return Self.reply()
            }
            if event.eventID == kAECountElements, let playlist {
                return Self.reply(NSAppleEventDescriptor(int32: Int32(state.entries[playlist, default: []].count)))
            }
            if wanted == MusicCode.source { return Self.reply(Self.list([reference(MusicCode.source, 1), reference(MusicCode.source, 2)])) }
            if property == MusicCode.kind { return Self.reply(NSAppleEventDescriptor(enumCode: container.forKeyword(AEKeyword(keyAEKeyData))?.int32Value == 1 ? MusicCode.library : MusicCode.fourCharCode("kShd"))) }
            if wanted == MusicCode.userPlaylist {
                return Self.reply(Self.list(playlistIDs.keys.sorted().map { reference(MusicCode.userPlaylist, $0, in: container) }))
            }
            if property == MusicCode.persistentID { return Self.reply(NSAppleEventDescriptor(string: playlist ?? "")) }
            if property == MusicCode.specialKind {
                let kind = playlist == "folder" ? MusicCode.folder : playlist == "system" ? MusicCode.fourCharCode("kSpL") : MusicCode.none
                return Self.reply(NSAppleEventDescriptor(enumCode: kind))
            }
            if property == MusicCode.smart || property == MusicCode.genius {
                return Self.reply(NSAppleEventDescriptor(boolean: playlist == (property == MusicCode.smart ? "smart" : "genius")))
            }
            if isColumn, let playlist {
                if state.missingColumns { return Self.reply(error: -1728) }
                var entries = state.entries[playlist, default: []]
                if state.metadataMode == "truncated", property == MusicCode.name { entries.removeLast() }
                let result = Self.list(entries.map { entry in
                    switch property {
                    case MusicCode.databaseID: return NSAppleEventDescriptor(int32: entry.databaseID)
                    case MusicCode.objectID: return NSAppleEventDescriptor(int32: entry.objectID)
                    case MusicCode.name: return NSAppleEventDescriptor(string: "Song \(entry.databaseID)")
                    case MusicCode.artist: return NSAppleEventDescriptor(string: "Artist")
                    case MusicCode.album: return NSAppleEventDescriptor(string: "Album")
                    default: return NSAppleEventDescriptor(string: "3:11")
                    }
                })
                if state.metadataMode == "changed", property == MusicCode.name { state.entries[playlist]?.reverse() }
                return Self.reply(result)
            }
            if property == MusicCode.name {
                let names = ["a": "Playlist 10", "b": "Playlist 2", "smart": "Smart", "genius": "Genius", "system": "System"]
                return Self.reply(NSAppleEventDescriptor(string: playlist.flatMap { names[$0] } ?? "Library"))
            }
            if property == MusicCode.databaseID, let playlist,
               let entry = state.entries[playlist]?.first(where: { $0.objectID == container.forKeyword(AEKeyword(keyAEKeyData))?.int32Value }) {
                return Self.reply(NSAppleEventDescriptor(int32: entry.databaseID))
            }
            if let filterID {
                let tracks = state.entries["a", default: []].filter { $0.databaseID == filterID }.map {
                    reference(MusicCode.track, $0.objectID, in: reference(MusicCode.userPlaylist, 1))
                }
                return Self.reply(Self.list(tracks))
            }
            throw NSError(domain: "UnexpectedTestEvent", code: -1, userInfo: [NSLocalizedDescriptionKey: direct.description])
        }
    }
}
