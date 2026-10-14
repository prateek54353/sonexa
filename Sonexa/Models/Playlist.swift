import Foundation
import SwiftData

@Model
final class Playlist {
    var id: UUID
    var name: String
    var dateCreated: Date
    var dateModified: Date
    var artworkPath: String?
    
    @Relationship(deleteRule: .cascade)
    var items: [PlaylistItem]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.dateModified = Date()
        self.items = []
    }
    
    var trackCount: Int {
        items.count
    }
    
    var totalDuration: TimeInterval {
        items.compactMap { $0.track }.reduce(0) { $0 + $1.duration }
    }
}

@Model
final class PlaylistItem {
    var id: UUID
    var order: Int
    var dateAdded: Date
    
    @Relationship(deleteRule: .nullify)
    var playlist: Playlist?
    
    @Relationship(deleteRule: .nullify)
    var track: Track?
    
    init(order: Int) {
        self.id = UUID()
        self.order = order
        self.dateAdded = Date()
    }
}

extension Playlist {
    static let preview = Playlist(name: "My Playlist")
}
