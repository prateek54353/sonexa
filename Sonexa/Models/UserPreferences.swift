import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var theme: String
    var hapticsEnabled: Bool
    var playbackHapticsEnabled: Bool
    var animatedArtworkEnabled: Bool
    var crossfadeEnabled: Bool
    var crossfadeDuration: Double
    var gaplessPlaybackEnabled: Bool
    var lyricsProviderOrder: [String]
    var autoFetchLyrics: Bool
    var autoFetchArtwork: Bool
    var scrobbleEnabled: Bool
    var scrobblePercentRequired: Int
    var sleepTimerDuration: TimeInterval?
    var sleepTimerEnabled: Bool
    var playbackSpeed: Double
    var equalizerEnabled: Bool
    var spatialAudioEnabled: Bool
    
    init() {
        self.id = UUID()
        self.theme = "dark"
        self.hapticsEnabled = true
        self.playbackHapticsEnabled = false
        self.animatedArtworkEnabled = true
        self.crossfadeEnabled = false
        self.crossfadeDuration = 2.0
        self.gaplessPlaybackEnabled = true
        self.lyricsProviderOrder = ["binilyrics", "musixmatch", "lrclib"]
        self.autoFetchLyrics = true
        self.autoFetchArtwork = true
        self.scrobbleEnabled = false
        self.scrobblePercentRequired = 50
        self.sleepTimerDuration = nil
        self.sleepTimerEnabled = false
        self.playbackSpeed = 1.0
        self.equalizerEnabled = false
        self.spatialAudioEnabled = false
    }
}

@Model
final class LastFmCredentials {
    var id: UUID
    var username: String
    var sessionKey: String
    var isConnected: Bool
    var lastScrobbleTime: Date?
    
    init() {
        self.id = UUID()
        self.username = ""
        self.sessionKey = ""
        self.isConnected = false
    }
}

@Model
final class PendingScrobble {
    var id: UUID
    var trackTitle: String
    var artist: String
    var album: String?
    var timestamp: TimeInterval
    var duration: TimeInterval
    var retryCount: Int
    var dateQueued: Date
    
    init(
        trackTitle: String,
        artist: String,
        album: String?,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.trackTitle = trackTitle
        self.artist = artist
        self.album = album
        self.timestamp = timestamp
        self.duration = duration
        self.retryCount = 0
        self.dateQueued = Date()
    }
}
