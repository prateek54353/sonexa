import Foundation
import SwiftData

@Model
final class Artist {
    var id: UUID
    var name: String
    var dateAdded: Date
    var lastPlayed: Date?
    var playCount: Int
    var artworkPath: String?
    
    @Relationship(deleteRule: .cascade)
    var tracks: [Track]
    
    @Relationship(deleteRule: .cascade)
    var albums: [Album]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateAdded = Date()
        self.playCount = 0
        self.tracks = []
        self.albums = []
    }
    
    var albumCount: Int {
        albums.count
    }
    
    var trackCount: Int {
        tracks.count
    }
}

extension Artist {
    static let preview = Artist(name: "Sample Artist")
}
