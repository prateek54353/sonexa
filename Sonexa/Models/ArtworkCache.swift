import Foundation
import SwiftData

@Model
final class ArtworkCache {
    var id: UUID
    var trackID: UUID?
    var albumID: UUID?
    var artistID: UUID?
    var localPath: String?
    var remoteURL: String?
    var isAnimated: Bool
    var cacheDate: Date
    var expiryDate: Date?
    var width: Int?
    var height: Int?
    var format: String?
    
    init() {
        self.id = UUID()
        self.isAnimated = false
        self.cacheDate = Date()
    }
}

@Model
final class ArtworkSearchResult {
    var id: UUID
    var query: String
    var artist: String
    var album: String
    var appleMusicURL: String?
    var animatedURL: String?
    var staticURL: String?
    var squareURL: String?
    var portraitURL: String?
    var isAvailable: Bool
    var searchDate: Date
    
    init(artist: String, album: String) {
        self.id = UUID()
        self.query = "\(artist) \(album)"
        self.artist = artist
        self.album = album
        self.isAvailable = false
        self.searchDate = Date()
    }
}
