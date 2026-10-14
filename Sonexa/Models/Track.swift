import Foundation
import SwiftData

@Model
final class Track {
    var id: UUID
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var trackNumber: Int?
    var totalTracks: Int?
    var discNumber: Int?
    var totalDiscs: Int?
    var genre: String?
    var year: Int?
    var composer: String?
    var duration: TimeInterval
    var fileURL: String
    var fileName: String
    var fileSize: Int64
    var fileType: String
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    var isFavourite: Bool
    var hasEmbeddedLyrics: Bool
    var hasEmbeddedArtwork: Bool
    var bitrate: Int?
    var sampleRate: Int?
    var channels: Int?
    
    @Relationship(deleteRule: .nullify, inverse: \Album.tracks)
    var albumEntity: Album?
    
    @Relationship(deleteRule: .nullify, inverse: \Artist.tracks)
    var artistEntity: Artist?
    
    init(
        title: String,
        artist: String,
        album: String,
        fileURL: String,
        fileName: String,
        fileSize: Int64,
        fileType: String,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = album
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileType = fileType
        self.duration = duration
        self.dateAdded = Date()
        self.playCount = 0
        self.isFavourite = false
        self.hasEmbeddedLyrics = false
        self.hasEmbeddedArtwork = false
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var displayName: String {
        title.isEmpty ? fileName : title
    }
}

extension Track {
    static let preview = Track(
        title: "Sample Track",
        artist: "Sample Artist",
        album: "Sample Album",
        fileURL: "/path/to/track.mp3",
        fileName: "track.mp3",
        fileSize: 1024 * 1024 * 5,
        fileType: "mp3",
        duration: 240.0
    )
}
