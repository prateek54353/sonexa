import Foundation
import SwiftData

@Model
final class Album {
    var id: UUID
    var name: String
    var artist: String
    var year: Int?
    var genre: String?
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    var artworkPath: String?
    
    @Relationship(deleteRule: .cascade)
    var tracks: [Track]
    
    init(name: String, artist: String) {
        self.id = UUID()
        self.name = name
        self.artist = artist
        self.dateAdded = Date()
        self.playCount = 0
        self.tracks = []
    }
    
    var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var trackCount: Int {
        tracks.count
    }
}

extension Album {
    static let preview = Album(name: "Sample Album", artist: "Sample Artist")
}
