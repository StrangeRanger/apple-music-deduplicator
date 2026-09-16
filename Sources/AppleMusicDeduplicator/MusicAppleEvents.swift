import AppKit
import Foundation

/// The small part of Music's scripting dictionary that this application uses.
/// Codes come from Music.app/Contents/Resources/com.apple.Music.sdef.
enum MusicCode {
    static let source = fourCharCode("cSrc")
    static let userPlaylist = fourCharCode("cUsP")
    static let track = fourCharCode("cTrk")
    static let name = fourCharCode("pnam")
    static let persistentID = fourCharCode("pPIS")
    static let objectID = fourCharCode("ID  ")
    static let databaseID = fourCharCode("pDID")
    static let kind = fourCharCode("pKnd")
    static let library = fourCharCode("kLib")
    static let specialKind = fourCharCode("pSpK")
    static let none = fourCharCode("kNon")
    static let folder = fourCharCode("kSpF")
    static let smart = fourCharCode("pSmt")
    static let genius = fourCharCode("pGns")
    static let artist = fourCharCode("pArt")
    static let album = fourCharCode("pAlb")
    static let time = fourCharCode("pTim")
    static let currentTrack = fourCharCode("pTrk")
    static let playerState = fourCharCode("pPlS")
    static let playerPosition = fourCharCode("pPos")
    static let playing = fourCharCode("kPSP")
    static let playback = fourCharCode("hook")
    static let play = fourCharCode("Play")
    static let pause = fourCharCode("Paus")
    static let once = fourCharCode("POne")

    static func fourCharCode(_ value: StaticString) -> OSType {
        precondition(value.utf8CodeUnitCount == 4)
        return value.withUTF8Buffer { $0.reduce(0) { ($0 << 8) | OSType($1) } }
    }
}

/// A connection is created and used on one background operation. Descriptors
/// never cross the concurrency boundary; only the app's Sendable models do.
final class MusicAppleEvents {
    typealias Sender = (NSAppleEventDescriptor) throws -> NSAppleEventDescriptor
    private let sender: Sender

    init(sender: @escaping Sender) {
        self.sender = sender
    }

    @MainActor
    static func prepareApplication() async throws {
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(withBundleIdentifier: "com.apple.Music") else {
            throw MusicAutomationError.musicUnavailable
        }
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
            .contains(where: { $0.isFinishedLaunching && !$0.isTerminated }) {
            return
        }

        // Direct Apple events do not launch their target. Await Launch Services
        // before creating the connection, keeping the deduplicator in front.
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.hides = true
        let application: NSRunningApplication
        do {
            application = try await workspace.openApplication(at: url, configuration: configuration)
        } catch {
            throw MusicAutomationError.musicLaunchFailed(error.localizedDescription)
        }
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        while !application.isFinishedLaunching {
            guard !application.isTerminated, ContinuousClock.now < deadline else {
                throw MusicAutomationError.musicLaunchFailed("Music did not finish starting. Please open Music and try again.")
            }
            // Suspending on the main actor lets launch notifications and UI
            // updates run while Music initializes its Apple-event handlers.
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    static func live() throws -> MusicAppleEvents {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Music") != nil else {
            throw MusicAutomationError.musicUnavailable
        }
        return MusicAppleEvents { event in
            try event.sendEvent(options: [.waitForReply, .canInteract], timeout: 120)
        }
    }

    @discardableResult
    func send(
        _ eventClass: AEEventClass,
        _ eventID: AEEventID,
        directObject: NSAppleEventDescriptor? = nil,
        parameters: [AEKeyword: NSAppleEventDescriptor] = [:]
    ) throws -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: eventClass, eventID: eventID,
            targetDescriptor: NSAppleEventDescriptor(bundleIdentifier: "com.apple.Music"),
            returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID)
        )
        if let directObject {
            event.setParam(directObject, forKeyword: AEKeyword(keyDirectObject))
        }
        for (key, value) in parameters {
            event.setParam(value, forKeyword: key)
        }

        let reply: NSAppleEventDescriptor
        do {
            reply = try sender(event)
        } catch {
            let error = error as NSError
            if error.code == -1743 { throw MusicAutomationError.permissionDenied }
            if error.code == -1728 { throw MusicAutomationError.objectNotFound }
            throw MusicAutomationError.appleEventFailed(error.localizedDescription)
        }
        // A successfully delivered event can still contain a Music-side error.
        if let error = reply.paramDescriptor(forKeyword: AEKeyword(keyErrorNumber)), error.int32Value != 0 {
            if error.int32Value == -1743 { throw MusicAutomationError.permissionDenied }
            if error.int32Value == -1728 { throw MusicAutomationError.objectNotFound }
            let message = reply.paramDescriptor(forKeyword: AEKeyword(keyErrorString))?.stringValue
                ?? "Music returned an automation error (\(error.int32Value))."
            throw MusicAutomationError.appleEventFailed(message)
        }
        return reply.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) ?? .null()
    }

    func get(_ reference: NSAppleEventDescriptor) throws -> NSAppleEventDescriptor {
        try send(AEEventClass(kAECoreSuite), AEEventID(kAEGetData), directObject: reference)
    }

    func value(_ property: OSType, of object: NSAppleEventDescriptor = .null()) throws -> NSAppleEventDescriptor {
        try get(Self.property(property, of: object))
    }

    static func property(_ code: OSType, of container: NSAppleEventDescriptor = .null()) -> NSAppleEventDescriptor {
        object(OSType(cProperty), in: container, form: OSType(formPropertyID), key: NSAppleEventDescriptor(typeCode: code))
    }

    static func elements(_ code: OSType, in container: NSAppleEventDescriptor = .null()) -> NSAppleEventDescriptor {
        // "all" is an absolute ordinal, not a normal enumerated value. Music
        // rejects an otherwise identical object specifier with typeEnumerated.
        let all = NSAppleEventDescriptor(
            descriptorType: DescType(typeAbsoluteOrdinal),
            data: NSAppleEventDescriptor(enumCode: OSType(kAEAll)).data
        )!
        return object(code, in: container, form: OSType(formAbsolutePosition), key: all)
    }

    static func object(
        _ code: OSType, in container: NSAppleEventDescriptor = .null(),
        form: OSType, key: NSAppleEventDescriptor
    ) -> NSAppleEventDescriptor {
        let record = NSAppleEventDescriptor.record()
        record.setDescriptor(NSAppleEventDescriptor(typeCode: code), forKeyword: AEKeyword(keyAEDesiredClass))
        record.setDescriptor(container, forKeyword: AEKeyword(keyAEContainer))
        record.setDescriptor(NSAppleEventDescriptor(enumCode: form), forKeyword: AEKeyword(keyAEKeyForm))
        record.setDescriptor(key, forKeyword: AEKeyword(keyAEKeyData))
        // A complete object-specifier record always supports this coercion.
        return record.coerce(toDescriptorType: DescType(typeObjectSpecifier))!
    }

    static func tracks(matching databaseID: Int32) -> NSAppleEventDescriptor {
        let examined = NSAppleEventDescriptor(descriptorType: DescType(typeObjectBeingExamined), data: Data())!
        let comparison = NSAppleEventDescriptor.record()
        comparison.setDescriptor(NSAppleEventDescriptor(enumCode: OSType(kAEEquals)), forKeyword: AEKeyword(keyAECompOperator))
        comparison.setDescriptor(property(MusicCode.databaseID, of: examined), forKeyword: AEKeyword(keyAEObject1))
        comparison.setDescriptor(NSAppleEventDescriptor(int32: databaseID), forKeyword: AEKeyword(keyAEObject2))
        return object(
            MusicCode.track, form: OSType(formTest),
            key: comparison.coerce(toDescriptorType: DescType(typeCompDescriptor))!
        )
    }

    static func list(_ descriptor: NSAppleEventDescriptor) throws -> [NSAppleEventDescriptor] {
        guard descriptor.descriptorType == typeAEList else {
            throw MusicAutomationError.appleEventFailed("Music returned an invalid list. Please try again.")
        }
        return (0..<descriptor.numberOfItems).map { descriptor.atIndex($0 + 1)! }
    }

    static func integer(_ descriptor: NSAppleEventDescriptor) throws -> Int {
        guard let value = descriptor.coerce(toDescriptorType: DescType(typeSInt32)) else {
            throw MusicAutomationError.appleEventFailed("Music returned an invalid track ID or count. Please scan again.")
        }
        return Int(value.int32Value)
    }

    private func boolean(_ property: OSType, of object: NSAppleEventDescriptor) throws -> Bool {
        let value = try value(property, of: object)
        guard let boolean = value.coerce(toDescriptorType: DescType(typeBoolean)) else {
            throw MusicAutomationError.appleEventFailed("Music returned an invalid playlist type. Please reload playlists.")
        }
        return boolean.booleanValue
    }

    struct Playlist {
        let reference: NSAppleEventDescriptor
        let id: String
        let name: String
        let sourceName: String
        let specialKind: OSType
        let smart: Bool
        let genius: Bool

        var canRemove: Bool { specialKind == MusicCode.none && !smart && !genius }
        var kindLabel: String {
            if smart { return "Smart" }
            if genius { return "Genius" }
            return specialKind == MusicCode.none ? "Playlist" : "System"
        }
        var occurrence: PlaylistOccurrence {
            PlaylistOccurrence(playlistID: id, playlistName: name, canRemove: canRemove)
        }
    }

    func userPlaylists(withIDs selectedIDs: Set<String>? = nil) throws -> [Playlist] {
        var playlists: [Playlist] = []
        for source in try Self.list(get(Self.elements(MusicCode.source))) {
            guard try value(MusicCode.kind, of: source).enumCodeValue == MusicCode.library else { continue }
            let sourceName = try value(MusicCode.name, of: source).stringValue.nonEmptyValue ?? "Library"
            for reference in try Self.list(get(Self.elements(MusicCode.userPlaylist, in: source))) {
                guard let id = try value(MusicCode.persistentID, of: reference).stringValue.nonEmptyValue else { continue }
                if let selectedIDs, !selectedIDs.contains(id) { continue }
                let specialKind = try value(MusicCode.specialKind, of: reference).enumCodeValue
                guard specialKind != MusicCode.folder else { continue }
                playlists.append(try Playlist(
                    reference: reference, id: id,
                    name: value(MusicCode.name, of: reference).stringValue.nonEmptyValue ?? "Untitled Playlist",
                    sourceName: sourceName, specialKind: specialKind,
                    smart: boolean(MusicCode.smart, of: reference), genius: boolean(MusicCode.genius, of: reference)
                ))
            }
        }
        return playlists
    }

    func trackCount(in playlist: Playlist) throws -> Int {
        try Self.integer(send(
            AEEventClass(kAECoreSuite), AEEventID(kAECountElements), directObject: playlist.reference,
            parameters: [AEKeyword(keyAEObjectClass): NSAppleEventDescriptor(typeCode: MusicCode.track)]
        ))
    }

    func trackColumn(_ property: OSType, in playlist: Playlist) throws -> [NSAppleEventDescriptor] {
        do {
            return try Self.list(value(property, of: Self.elements(MusicCode.track, in: playlist.reference)))
        } catch MusicAutomationError.objectNotFound {
            // Music returns -1728 for a property of an empty track collection.
            // Confirm the playlist still exists and is empty before accepting it.
            guard try trackCount(in: playlist) == 0 else { throw MusicAutomationError.playlistChanged(playlist.name) }
            return []
        }
    }

    func databaseIDs(in playlist: Playlist) throws -> [Int] {
        try autoreleasepool {
            try trackColumn(MusicCode.databaseID, in: playlist).map(Self.integer)
        }
    }

    struct TrackEntry {
        let databaseID: Int
        let objectID: Int32
    }

    func entries(in playlist: Playlist) throws -> [TrackEntry] {
        let databaseIDs = try databaseIDs(in: playlist)
        let objectIDs = try trackColumn(MusicCode.objectID, in: playlist).map(Self.integer)
        guard try self.databaseIDs(in: playlist) == databaseIDs else {
            throw MusicAutomationError.playlistChanged(playlist.name)
        }
        guard objectIDs.count == databaseIDs.count else {
            throw MusicAutomationError.invalidTrackData(playlist.name)
        }
        return zip(databaseIDs, objectIDs).map { TrackEntry(databaseID: $0.0, objectID: Int32($0.1)) }
    }

    func delete(_ entry: TrackEntry, from playlist: Playlist) throws {
        guard playlist.canRemove else {
            throw MusicAutomationError.appleEventFailed("This playlist cannot be edited by Music automation.")
        }
        // Use stable object IDs inside this user playlist, independent of play
        // order. Music's sandbox disallows setting its global fixed-indexing
        // property; no index-based deletion or library/global reference is used.
        let reference = Self.object(
            MusicCode.track, in: playlist.reference, form: OSType(formUniqueID),
            key: NSAppleEventDescriptor(int32: entry.objectID)
        )
        guard try Self.integer(value(MusicCode.databaseID, of: reference)) == entry.databaseID else {
            throw MusicAutomationError.playlistChanged(playlist.name)
        }
        try send(AEEventClass(kAECoreSuite), AEEventID(kAEDelete), directObject: reference)
    }

    func play(databaseID: Int32, title: String) throws {
        // Resolve the filter before playback. Music rejects an item-of-filter
        // reference, and the requested track must be the explicit direct object.
        let matches: [NSAppleEventDescriptor]
        do {
            matches = try Self.list(get(Self.tracks(matching: databaseID)))
        } catch MusicAutomationError.objectNotFound {
            throw MusicAutomationError.trackUnavailable(title)
        }
        guard let track = matches.first else { throw MusicAutomationError.trackUnavailable(title) }
        try send(
            MusicCode.playback, MusicCode.play, directObject: track,
            parameters: [MusicCode.once: NSAppleEventDescriptor(boolean: true)]
        )
    }

    func pause() throws {
        try send(MusicCode.playback, MusicCode.pause)
    }
}

private extension Optional where Wrapped == String {
    var nonEmptyValue: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
