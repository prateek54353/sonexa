import SwiftUI
import AVFoundation
import MediaPlayer

@main
struct SonexaApp: App {
    @StateObject private var playbackEngine = PlaybackEngine.shared
    @StateObject private var libraryManager = LibraryManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playbackEngine)
                .environmentObject(libraryManager)
                .environmentObject(settingsManager)
                .onAppear {
                    setupRemoteCommandCenter()
                }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak playbackEngine] event in
            playbackEngine?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak playbackEngine] event in
            playbackEngine?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak playbackEngine] event in
            playbackEngine?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak playbackEngine] event in
            playbackEngine?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak playbackEngine] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                playbackEngine?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
}
