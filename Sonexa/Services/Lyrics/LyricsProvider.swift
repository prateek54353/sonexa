import Foundation

protocol LyricsProvider {
    var name: String { get }
    var priority: Int { get }
    
    func searchLyrics(track: String, artist: String, album: String?) async throws -> LyricsSearchResult
    func fetchLyrics(trackID: String) async throws -> LyricsData
}

struct LyricsSearchResult {
    let trackID: String
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval?
    let hasSyncedLyrics: Bool
    let confidence: Double
}

struct LyricsData {
    let plainLyrics: String?
    let syncedLyrics: [LyricsLine]?
    let language: String?
    let source: String
    let isWordSynced: Bool
}

enum LyricsProviderError: Error {
    case networkError(Error)
    case notFound
    case rateLimited
    case authenticationFailed
    case invalidResponse
    case serviceUnavailable
}
