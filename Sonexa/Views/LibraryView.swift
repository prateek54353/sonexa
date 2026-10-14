import SwiftUI

enum LibrarySection: String, CaseIterable {
    case songs = "Songs"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"
    case favourites = "Favourites"
}

struct LibraryView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var playbackEngine: PlaybackEngine
    
    @State private var selectedSection: LibrarySection = .songs
    @State private var searchText = ""
    @State private var sortOption: SortOption = .title
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case artist = "Artist"
        case album = "Album"
        case dateAdded = "Date Added"
        case duration = "Duration"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(LibrarySection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedSection {
                        case .songs:
                            songsSection
                        case .albums:
                            albumsSection
                        case .artists:
                            artistsSection
                        case .playlists:
                            playlistsSection
                        case .favourites:
                            favouritesSection
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .background(Colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                sortOption = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
    
    private var songsSection: some View {
        let filteredTracks = filteredAndSortedTracks()
        
        if filteredTracks.isEmpty {
            emptyView(message: "No songs found")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filteredTracks) { track in
                    TrackRow(track: track)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playbackEngine.playTrack(track)
                        }
                }
            }
        }
    }
    
    private var albumsSection: some View {
        let filteredAlbums = libraryManager.albums.filter { album in
            searchText.isEmpty ||
            album.name.localizedCaseInsensitiveContains(searchText) ||
            album.artist.localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredAlbums.isEmpty {
            emptyView(message: "No albums found")
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.lg) {
                ForEach(filteredAlbums) { album in
                    AlbumCard(album: album)
                }
            }
            .padding(Spacing.lg)
        }
    }
    
    private var artistsSection: some View {
        let filteredArtists = libraryManager.artists.filter { artist in
            searchText.isEmpty ||
            artist.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredArtists.isEmpty {
            emptyView(message: "No artists found")
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.lg) {
                ForEach(filteredArtists) { artist in
                    ArtistCard(artist: artist)
                }
            }
            .padding(Spacing.lg)
        }
    }
    
    private var playlistsSection: some View {
        let filteredPlaylists = libraryManager.playlists.filter { playlist in
            searchText.isEmpty ||
            playlist.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredPlaylists.isEmpty {
            emptyView(message: "No playlists found")
        } else {
            LazyVStack(spacing: Spacing.md) {
                ForEach(filteredPlaylists) { playlist in
                    PlaylistRow(playlist: playlist)
                }
            }
            .padding(Spacing.lg)
        }
    }
    
    private var favouritesSection: some View {
        let filteredFavourites = libraryManager.favouriteTracks.filter { track in
            searchText.isEmpty ||
            track.title.localizedCaseInsensitiveContains(searchText) ||
            track.artist.localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredFavourites.isEmpty {
            emptyView(message: "No favourites found")
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filteredFavourites) { track in
                    TrackRow(track: track)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playbackEngine.playTrack(track)
                        }
            }
        }
    }
    
    private func filteredAndSortedTracks() -> [Track] {
        var tracks = libraryManager.tracks
        
        // Filter
        if !searchText.isEmpty {
            tracks = tracks.filter { track in
                track.title.localizedCaseInsensitiveContains(searchText) ||
                track.artist.localizedCaseInsensitiveContains(searchText) ||
                track.album.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .title:
            tracks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .artist:
            tracks.sort { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
        case .album:
            tracks.sort { $0.album.localizedCaseInsensitiveCompare($1.album) == .orderedAscending }
        case .dateAdded:
            tracks.sort { $0.dateAdded > $1.dateAdded }
        case .duration:
            tracks.sort { $0.duration > $1.duration }
        }
        
        return tracks
    }
    
    private func emptyView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "music.note")
                .font(.system(size: 50))
                .foregroundColor(Colors.secondaryText)
            
            Text(message)
                .font(Typography.body)
                .foregroundColor(Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxxl)
    }
}

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var libraryManager: LibraryManager
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Album Art placeholder
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Colors.tertiaryBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(track.displayName)
                    .font(Typography.body)
                    .foregroundColor(Colors.primaryText)
                    .lineLimit(1)
                
                Text("\(track.artist) • \(track.album)")
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(Typography.caption1)
                .foregroundColor(Colors.secondaryText)
            
            Button(action: {
                libraryManager.toggleFavourite(track)
            }) {
                Image(systemName: track.isFavourite ? "heart.fill" : "heart")
                    .foregroundColor(track.isFavourite ? Colors.accent : Colors.secondaryText)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Colors.background)
    }
}

struct AlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Colors.tertiaryBackground)
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "square.stack")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(album.name)
                    .font(Typography.subheadline)
                    .foregroundColor(Colors.primaryText)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Colors.tertiaryBackground)
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "person")
                    .font(.system(size: 40))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(artist.name)
                    .font(Typography.subheadline)
                    .foregroundColor(Colors.primaryText)
                    .lineLimit(1)
                
                Text("\(artist.albumCount) albums")
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Colors.tertiaryBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 24))
                    .foregroundColor(Colors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(playlist.name)
                    .font(Typography.body)
                    .foregroundColor(Colors.primaryText)
                
                Text("\(playlist.trackCount) tracks")
                    .font(Typography.caption1)
                    .foregroundColor(Colors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Colors.secondaryText)
        }
        .padding(Spacing.lg)
        .cardStyle()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Colors.secondaryText)
            
            TextField("Search", text: $text)
                .foregroundColor(Colors.primaryText)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Colors.secondaryText)
                }
            }
        }
        .padding(Spacing.md)
        .background(Colors.secondaryBackground)
        .cornerRadius(CornerRadius.md)
    }
}
