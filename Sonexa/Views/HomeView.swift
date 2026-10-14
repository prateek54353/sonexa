import SwiftUI

struct HomeView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var playbackEngine: PlaybackEngine
    @State private var isImporting: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // Recently Played
                    if !libraryManager.tracks.isEmpty {
                        recentlyPlayedSection
                    }
                    
                    // Recently Added
                    if !libraryManager.tracks.isEmpty {
                        recentlyAddedSection
                    }
                    
                    // Favourites
                    if !libraryManager.favouriteTracks.isEmpty {
                        favouritesSection
                    }
                    
                    // Playlists
                    if !libraryManager.playlists.isEmpty {
                        playlistsSection
                    }
                    
                    // Empty State
                    if libraryManager.tracks.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Sonexa")
            .background(Colors.background)
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [
                    .mp3,
                    .mpeg4Audio,
                    .wav,
                    .aiff,
                    .audio
                ],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task {
                        do {
                            try await libraryManager.importFiles(urls: urls)
                        } catch {
                            print("Import failed: \(error)")
                        }
                    }
                case .failure(let error):
                    print("File picker failed: \(error)")
                }
            }
        }
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recently Played")
                .font(Typography.headline)
                .foregroundColor(Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(libraryManager.tracks.prefix(10)) { track in
                        TrackCard(track: track)
                    }
                }
            }
        }
    }
    
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recently Added")
                .font(Typography.headline)
                .foregroundColor(Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(libraryManager.tracks.sorted { $0.dateAdded > $1.dateAdded }.prefix(10)) { track in
                        TrackCard(track: track)
                    }
                }
            }
        }
    }
    
    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Favourites")
                .font(Typography.headline)
                .foregroundColor(Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(libraryManager.favouriteTracks.prefix(10)) { track in
                        TrackCard(track: track)
                    }
                }
            }
        }
    }
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Playlists")
                .font(Typography.headline)
                .foregroundColor(Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(libraryManager.playlists) { playlist in
                        PlaylistCard(playlist: playlist)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(Colors.secondaryText)
            
            Text("No Music Yet")
                .font(Typography.title2)
                .foregroundColor(Colors.primaryText)
            
            Text("Import your music library to get started")
                .font(Typography.body)
                .foregroundColor(Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                isImporting = true
            }) {
                Text("Import Music")
                    .font(Typography.headline)
            }
            .buttonStyle(StandardButtonStyle())
        }
        .padding(Spacing.xxxl)
    }
}

struct TrackCard: View {
    let track: Track
    @EnvironmentObject var playbackEngine: PlaybackEngine
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Colors.tertiaryBackground)
                    .frame(width: 140, height: 140)
                
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(track.displayName)
                    .font(Typography.subheadline)
                    .foregroundColor(Colors.primaryText)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
        }
        .onTapGesture {
            playbackEngine.playTrack(track)
        }
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Colors.tertiaryBackground)
                    .frame(width: 140, height: 140)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(playlist.name)
                    .font(Typography.subheadline)
                    .foregroundColor(Colors.primaryText)
                    .lineLimit(1)
                
                Text("\(playlist.trackCount) tracks")
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
            }
            .frame(width: 140, alignment: .leading)
        }
    }
}
