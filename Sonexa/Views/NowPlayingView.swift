import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @EnvironmentObject var libraryManager: LibraryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showLyrics: Bool = false
    @State private var showQueue: Bool = false
    @State private var showSettings: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(Colors.primaryText)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    if let track = playbackEngine.currentTrack {
                        Text("Now Playing")
                            .font(Typography.headline)
                            .foregroundColor(Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Colors.primaryText)
                            .font(.title2)
                    }
                }
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Artwork
                        if let track = playbackEngine.currentTrack {
                            artworkView
                                .frame(height: geometry.size.width - Spacing.xxxl * 2)
                            
                            // Track Info
                            VStack(spacing: Spacing.sm) {
                                Text(track.title)
                                    .font(Typography.title2)
                                    .foregroundColor(Colors.primaryText)
                                    .multilineTextAlignment(.center)
                                
                                Text(track.artist)
                                    .font(Typography.body)
                                    .foregroundColor(Colors.secondaryText)
                                
                                Text(track.album)
                                    .font(Typography.subheadline)
                                    .foregroundColor(Colors.secondaryText)
                            }
                            
                            // Progress
                            VStack(spacing: Spacing.sm) {
                                Slider(
                                    value: Binding(
                                        get: { playbackEngine.currentTime },
                                        set: { playbackEngine.seek(to: $0) }
                                    ),
                                    in: 0...playbackEngine.duration
                                )
                                .accentColor(Colors.accent)
                                
                                HStack {
                                    Text(formatTime(playbackEngine.currentTime))
                                        .font(Typography.caption1)
                                        .foregroundColor(Colors.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text(formatTime(playbackEngine.duration))
                                        .font(Typography.caption1)
                                        .foregroundColor(Colors.secondaryText)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                            
                            // Controls
                            HStack(spacing: Spacing.xl) {
                                // Shuffle
                                Button(action: {
                                    playbackEngine.toggleShuffle()
                                }) {
                                    Image(systemName: playbackEngine.shuffleMode == .on ? "shuffle.circle.fill" : "shuffle.circle")
                                        .font(.system(size: 40))
                                        .foregroundColor(playbackEngine.shuffleMode == .on ? Colors.accent : Colors.primaryText)
                                }
                                
                                // Previous
                                Button(action: {
                                    playbackEngine.playPrevious()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Colors.primaryText)
                                }
                                
                                // Play/Pause
                                Button(action: {
                                    playbackEngine.togglePlayPause()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Colors.primaryText)
                                            .frame(width: 70, height: 70)
                                        
                                        Image(systemName: playbackEngine.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Colors.background)
                                    }
                                }
                                
                                // Next
                                Button(action: {
                                    playbackEngine.playNext()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Colors.primaryText)
                                }
                                
                                // Repeat
                                Button(action: {
                                    playbackEngine.toggleRepeat()
                                }) {
                                    Image(systemName: repeatIcon)
                                        .font(.system(size: 40))
                                        .foregroundColor(playbackEngine.repeatMode != .off ? Colors.accent : Colors.primaryText)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                            
                            // Secondary Controls
                            HStack(spacing: Spacing.xl) {
                                Button(action: {
                                    libraryManager.toggleFavourite(track)
                                }) {
                                    Image(systemName: track.isFavourite ? "heart.fill" : "heart")
                                        .font(.system(size: 24))
                                        .foregroundColor(track.isFavourite ? Colors.accent : Colors.primaryText)
                                }
                                
                                Button(action: {
                                    showQueue = true
                                }) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 24))
                                        .foregroundColor(Colors.primaryText)
                                }
                                
                                Button(action: {
                                    showLyrics = true
                                }) {
                                    Image(systemName: "quote.bubble")
                                        .font(.system(size: 24))
                                        .foregroundColor(Colors.primaryText)
                                }
                                
                                Button(action: {
                                    // TODO: Show audio settings
                                }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 24))
                                        .foregroundColor(Colors.primaryText)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Colors.background)
            .sheet(isPresented: $showLyrics) {
                LyricsView()
            }
            .sheet(isPresented: $showQueue) {
                QueueView()
            }
            .sheet(isPresented: $showSettings) {
                TrackSettingsView()
            }
        }
    }
    
    private var artworkView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Colors.tertiaryBackground)
            
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(Colors.secondaryText)
        }
    }
    
    private var repeatIcon: String {
        switch playbackEngine.repeatMode {
        case .off:
            return "repeat.circle"
        case .all:
            return "repeat.circle.fill"
        case .one:
            return "repeat.1.circle.fill"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct MiniPlayer: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @State private var showNowPlaying: Bool = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Colors.tertiaryBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(Colors.secondaryText)
            }
            
            // Track Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let track = playbackEngine.currentTrack {
                    Text(track.title)
                        .font(Typography.subheadline)
                        .foregroundColor(Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(Typography.caption1)
                        .foregroundColor(Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: Spacing.lg) {
                Button(action: {
                    playbackEngine.togglePlayPause()
                }) {
                    Image(systemName: playbackEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Colors.primaryText)
                }
                
                Button(action: {
                    playbackEngine.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Colors.primaryText)
                }
            }
        }
        .padding(Spacing.md)
        .background(Colors.secondaryBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(radius: 10)
        .onTapGesture {
            showNowPlaying = true
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}

struct QueueView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine
    
    var body: some View {
        NavigationStack {
            List {
                if playbackEngine.queue.isEmpty {
                    Text("Queue is empty")
                        .foregroundColor(Colors.secondaryText)
                } else {
                    ForEach(Array(playbackEngine.queue.enumerated()), id: \.element.id) { index, track in
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(track.title)
                                    .font(Typography.body)
                                    .foregroundColor(Colors.primaryText)
                                
                                Text(track.artist)
                                    .font(Typography.caption1)
                                    .foregroundColor(Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            if index == playbackEngine.queueIndex {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(Colors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playbackEngine.queueIndex = index
                            playbackEngine.playTrack(track)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            playbackEngine.removeFromQueue(at: index)
                        }
                    }
                }
            }
            .navigationTitle("Queue")
            .background(Colors.background)
            .scrollContentBackground(.hidden)
        }
    }
}

struct TrackSettingsView: View {
    @EnvironmentObject var playbackEngine: PlaybackEngine
    
    var body: some View {
        NavigationStack {
            List {
                if let track = playbackEngine.currentTrack {
                    Section("Track Info") {
                        HStack {
                            Text("Title")
                            Spacer()
                            Text(track.title)
                                .foregroundColor(Colors.secondaryText)
                        }
                        
                        HStack {
                            Text("Artist")
                            Spacer()
                            Text(track.artist)
                                .foregroundColor(Colors.secondaryText)
                        }
                        
                        HStack {
                            Text("Album")
                            Spacer()
                            Text(track.album)
                                .foregroundColor(Colors.secondaryText)
                        }
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(track.formattedDuration)
                                .foregroundColor(Colors.secondaryText)
                        }
                    }
                    
                    Section("Actions") {
                        NavigationLink {
                            MetadataEditorView(track: track)
                        } label: {
                            Text("Edit Metadata")
                        }
                        
                        Button("Add to Playlist") {
                            // TODO: Show playlist selection
                        }
                    }
                }
            }
            .navigationTitle("Track Settings")
            .background(Colors.background)
            .scrollContentBackground(.hidden)
        }
    }
}
