import Foundation
import SwiftData

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var preferences: UserPreferences?
    @Published var lastFmCredentials: LastFmCredentials?
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }
    
    private func loadSettings() {
        guard let context = modelContext else { return }
        
        let prefsDescriptor = FetchDescriptor<UserPreferences>()
        preferences = (try? context.fetch(prefsDescriptor).first) ?? UserPreferences()
        
        let credsDescriptor = FetchDescriptor<LastFmCredentials>()
        lastFmCredentials = (try? context.fetch(credsDescriptor).first) ?? LastFmCredentials()
    }
    
    func savePreferences() {
        guard let context = modelContext,
              let prefs = preferences else { return }
        
        if (try? context.fetch(FetchDescriptor<UserPreferences>()).first) == nil {
            context.insert(prefs)
        }
        
        try? context.save()
    }
    
    func saveLastFmCredentials() {
        guard let context = modelContext,
              let creds = lastFmCredentials else { return }
        
        if (try? context.fetch(FetchDescriptor<LastFmCredentials>()).first) == nil {
            context.insert(creds)
        }
        
        try? context.save()
    }
    
    // MARK: - Theme
    
    var currentTheme: AppTheme {
        guard let themeString = preferences?.theme else { return .dark }
        return AppTheme(rawValue: themeString) ?? .dark
    }
    
    func setTheme(_ theme: AppTheme) {
        preferences?.theme = theme.rawValue
        savePreferences()
    }
    
    // MARK: - Haptics
    
    var hapticsEnabled: Bool {
        preferences?.hapticsEnabled ?? true
    }
    
    func setHapticsEnabled(_ enabled: Bool) {
        preferences?.hapticsEnabled = enabled
        savePreferences()
    }
    
    // MARK: - Animated Artwork
    
    var animatedArtworkEnabled: Bool {
        preferences?.animatedArtworkEnabled ?? true
    }
    
    func setAnimatedArtworkEnabled(_ enabled: Bool) {
        preferences?.animatedArtworkEnabled = enabled
        savePreferences()
    }
    
    // MARK: - Lyrics
    
    var autoFetchLyrics: Bool {
        preferences?.autoFetchLyrics ?? true
    }
    
    func setAutoFetchLyrics(_ enabled: Bool) {
        preferences?.autoFetchLyrics = enabled
        savePreferences()
    }
    
    var lyricsProviderOrder: [String] {
        preferences?.lyricsProviderOrder ?? ["binilyrics", "musixmatch", "lrclib"]
    }
    
    func setLyricsProviderOrder(_ order: [String]) {
        preferences?.lyricsProviderOrder = order
        savePreferences()
    }
    
    // MARK: - Last.fm
    
    var scrobbleEnabled: Bool {
        preferences?.scrobbleEnabled ?? false
    }
    
    func setScrobbleEnabled(_ enabled: Bool) {
        preferences?.scrobbleEnabled = enabled
        savePreferences()
    }
    
    var lastFmConnected: Bool {
        lastFmCredentials?.isConnected ?? false
    }
    
    func connectLastFm(username: String, sessionKey: String) {
        lastFmCredentials?.username = username
        lastFmCredentials?.sessionKey = sessionKey
        lastFmCredentials?.isConnected = true
        saveLastFmCredentials()
    }
    
    func disconnectLastFm() {
        lastFmCredentials?.username = ""
        lastFmCredentials?.sessionKey = ""
        lastFmCredentials?.isConnected = false
        saveLastFmCredentials()
    }
    
    // MARK: - Sleep Timer
    
    var sleepTimerEnabled: Bool {
        preferences?.sleepTimerEnabled ?? false
    }
    
    var sleepTimerDuration: TimeInterval? {
        preferences?.sleepTimerDuration
    }
    
    func setSleepTimer(duration: TimeInterval?) {
        preferences?.sleepTimerDuration = duration
        preferences?.sleepTimerEnabled = duration != nil
        savePreferences()
    }
    
    func clearSleepTimer() {
        preferences?.sleepTimerDuration = nil
        preferences?.sleepTimerEnabled = false
        savePreferences()
    }
    
    // MARK: - Auto-import Folder
    
    var autoImportFolderEnabled: Bool {
        preferences?.autoImportFolderEnabled ?? false
    }
    
    func setAutoImportFolderEnabled(_ enabled: Bool) {
        preferences?.autoImportFolderEnabled = enabled
        savePreferences()
    }
    
    func setAutoImportFolder(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
            preferences?.autoImportFolderBookmark = bookmark
            savePreferences()
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
    
    func clearAutoImportFolder() {
        preferences?.autoImportFolderBookmark = nil
        savePreferences()
    }
    
    func getAutoImportFolderURL() -> URL? {
        guard let bookmark = preferences?.autoImportFolderBookmark else { return nil }
        
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                // Bookmark is stale, need to re-select
                clearAutoImportFolder()
                return nil
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            clearAutoImportFolder()
            return nil
        }
    }
}
