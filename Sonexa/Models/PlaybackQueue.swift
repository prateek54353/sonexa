import Foundation
import SwiftData

@Model
final class QueueItem {
    var id: UUID
    var order: Int
    var dateAdded: Date
    
    @Relationship(deleteRule: .nullify)
    var track: Track?
    
    init(order: Int) {
        self.id = UUID()
        self.order = order
        self.dateAdded = Date()
    }
}

@Model
final class PlaybackHistory {
    var id: UUID
    var datePlayed: Date
    var position: TimeInterval
    
    @Relationship(deleteRule: .nullify)
    var track: Track?
    
    init(position: TimeInterval) {
        self.id = UUID()
        self.datePlayed = Date()
        self.position = position
    }
}
