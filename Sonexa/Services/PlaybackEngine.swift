import Foundation
import AVFoundation
import MediaPlayer
import Combine

enum RepeatMode: String, CaseIterable {
    case off
    case all
    case one
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .all: return "All"
        case .one: return "One"
        }
    }
}

enum ShuffleMode: String, CaseIterable {
    case off
    case on
    
    var displayName: String {
        switch self {
        case .off: return "Off"
        case .on: return "On"
        }
    }
}

@MainActor
class PlaybackEngine: ObservableObject {
    static let shared = PlaybackEngine()
    
    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .off
    @Published var shuffleMode: ShuffleMode = .off
    @Published var queue: [Track] = []
    @Published var queueIndex: Int = 0
    @Published var playbackRate: Float = 1.0
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var queueItems: [Track] = []
    private var originalQueue: [Track] = []
    
    private init() {}
    
    // MARK: - Playback Control
    
    func play() {
        guard let player = player else { return }
        player.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func pause() {
        guard let player = player else { return }
        player.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func playTrack(_ track: Track) {
        guard let url = URL(string: track.fileURL) else { return }
        
        currentTrack = track
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        setupAudioSession()
        play()
        
        if let currentItem = playerItem {
            duration = currentItem.duration.seconds
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleTrackCompletion()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
    }
    
    func playNext() {
        guard !queue.isEmpty else { return }
        
        switch repeatMode {
        case .one:
            if let currentTrack = currentTrack {
                playTrack(currentTrack)
                seek(to: 0)
            }
        default:
            if shuffleMode == .on {
                queueIndex = Int.random(in: 0..<queue.count)
            } else {
                queueIndex = (queueIndex + 1) % queue.count
            }
            
            if queueIndex < queue.count {
                playTrack(queue[queueIndex])
            }
        }
    }
    
    func playPrevious() {
        guard !queue.isEmpty else { return }
        
        if currentTime > 3.0 {
            seek(to: 0)
        } else {
            if shuffleMode == .on {
                queueIndex = Int.random(in: 0..<queue.count)
            } else {
                queueIndex = (queueIndex - 1 + queue.count) % queue.count
            }
            
            if queueIndex >= 0 && queueIndex < queue.count {
                playTrack(queue[queueIndex])
            }
        }
    }
    
    func setQueue(_ tracks: [Track], startIndex: Int = 0) {
        queue = tracks
        originalQueue = tracks
        queueIndex = startIndex
        
        if startIndex < tracks.count {
            playTrack(tracks[startIndex])
        }
    }
    
    func addToQueue(_ tracks: [Track]) {
        queue.append(contentsOf: tracks)
        originalQueue.append(contentsOf: tracks)
    }
    
    func clearQueue() {
        queue.removeAll()
        originalQueue.removeAll()
        queueIndex = 0
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count else { return }
        queue.remove(at: index)
        originalQueue.remove(at: index)
        
        if index < queueIndex {
            queueIndex -= 1
        }
    }
    
    func toggleShuffle() {
        shuffleMode = shuffleMode == .off ? .on : .off
        
        if shuffleMode == .on {
            let current = queue.isEmpty ? nil : queue[queueIndex]
            queue.shuffle()
            if let current = current, let newIndex = queue.firstIndex(where: { $0.id == current.id }) {
                queueIndex = newIndex
            }
        } else {
            let current = queue.isEmpty ? nil : queue[queueIndex]
            queue = originalQueue
            if let current = current, let newIndex = queue.firstIndex(where: { $0.id == current.id }) {
                queueIndex = newIndex
            }
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }
    
    // MARK: - Private Methods
    
    private func handleTrackCompletion() {
        switch repeatMode {
        case .one:
            if let currentTrack = currentTrack {
                playTrack(currentTrack)
                seek(to: 0)
            }
        case .off:
            if queueIndex < queue.count - 1 {
                playNext()
            } else {
                pause()
                seek(to: 0)
            }
        case .all:
            playNext()
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .defaultPlayback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo: [String: Any] = [:]
        
        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
