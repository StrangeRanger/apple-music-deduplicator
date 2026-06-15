import Foundation

struct PlaylistSummary: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let sourceName: String
    let trackCount: Int
    let canRemoveTracks: Bool
    let kindLabel: String
}

struct ScannedTrackOccurrence: Hashable, Sendable {
    let trackKey: String
    let title: String
    let artist: String
    let album: String
    let time: String
    let playlistID: String
    let playlistName: String
    let canRemoveFromPlaylist: Bool
}

struct DuplicateSong: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let time: String
    let occurrences: [PlaylistOccurrence]
}

struct PlaylistOccurrence: Identifiable, Hashable, Sendable {
    var id: String { playlistID }

    let playlistID: String
    let playlistName: String
    let canRemove: Bool
}

struct RemovalRequest: Hashable, Sendable {
    let trackKey: String
    let playlistID: String
    let trackTitle: String
    let playlistName: String
}

struct RemovalProgress: Equatable, Sendable {
    let completedRequests: Int
    let totalRequests: Int
    let removedEntries: Int
    let currentTrackTitle: String
    let currentPlaylistName: String

    var fractionCompleted: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(completedRequests) / Double(totalRequests)
    }

    var countText: String {
        "\(completedRequests) of \(totalRequests)"
    }
}

struct RemovalResult: Sendable {
    let requestedCount: Int
    let removedEntries: Int
    let failures: [RemovalFailure]
}

struct RemovalFailure: Identifiable, Sendable {
    var id: String { "\(trackKey)-\(playlistID)-\(message)" }

    let trackKey: String
    let playlistID: String
    let trackTitle: String
    let playlistName: String
    let message: String
}
