import Foundation
import SwiftData

enum LyricsType: String, Codable {
    case plain
    case lineSynced
    case wordSynced
}

@Model
final class LyricsDocument {
    var id: UUID
    var trackID: UUID
    var lyrics: String
    var type: LyricsType
    var language: String?
    var provider: String
    var source: String
    var matchConfidence: Double
    var retrievalTime: Date
    var syncOffset: TimeInterval
    var userEdited: Bool
    
    @Relationship(deleteRule: .nullify)
    var track: Track?
    
    init(
        trackID: UUID,
        lyrics: String,
        type: LyricsType,
        provider: String,
        source: String
    ) {
        self.id = UUID()
        self.trackID = trackID
        self.lyrics = lyrics
        self.type = type
        self.provider = provider
        self.source = source
        self.matchConfidence = 1.0
        self.retrievalTime = Date()
        self.syncOffset = 0.0
        self.userEdited = false
    }
    
    var isSynchronized: Bool {
        type == .lineSynced || type == .wordSynced
    }
}

struct LyricsLine: Identifiable, Codable {
    let id: UUID
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval?
    var words: [LyricsWord]?
    
    init(text: String, startTime: TimeInterval, endTime: TimeInterval? = nil) {
        self.id = UUID()
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}

struct LyricsWord: Identifiable, Codable {
    let id: UUID
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    
    init(text: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.id = UUID()
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }
}
