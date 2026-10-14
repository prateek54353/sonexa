import SwiftUI

struct SearchView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var playbackEngine: PlaybackEngine
    
    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all
    @State private var recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case songs = "Songs"
        case albums = "Albums"
        case artists = "Artists"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                
                // Scope Picker
                Picker("Scope", selection: $selectedScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)
                
                // Results
                ScrollView {
                    VStack(spacing: 0) {
                        if searchText.isEmpty {
                            recentSearchesView
                        } else {
                            searchResultsView
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .background(Colors.background)
            .task(id: searchText) {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return }
                recentSearches.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
                recentSearches.insert(query, at: 0)
                recentSearches = Array(recentSearches.prefix(10))
                UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
            }
        }
    }
    
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Recent Searches")
                .font(Typography.headline)
                .foregroundColor(Colors.primaryText)
                .padding(.horizontal, Spacing.lg)
            
            if recentSearches.isEmpty {
                Text("No recent searches")
                    .font(Typography.body)
                    .foregroundColor(Colors.secondaryText)
                    .padding(.horizontal, Spacing.lg)
            } else {
                ForEach(recentSearches, id: \.self) { query in
                    Button { searchText = query } label: {
                        Label(query, systemImage: "clock")
                            .foregroundColor(Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                Button("Clear Recent Searches", role: .destructive) {
                    recentSearches.removeAll()
                    UserDefaults.standard.removeObject(forKey: "recentSearches")
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.top, Spacing.lg)
    }
    
    private var searchResultsView: some View {
        VStack(spacing: Spacing.xl) {
            switch selectedScope {
            case .all:
                allResults
            case .songs:
                LazyVStack(spacing: 0) {
                    ForEach(songResults) { track in
                        TrackRow(track: track)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playbackEngine.playTrack(track)
                            }
                    }
                }
            case .albums:
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.lg) {
                    ForEach(albumResults) { album in
                        AlbumCard(album: album)
                    }
                }
            case .artists:
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.lg) {
                    ForEach(artistResults) { artist in
                        ArtistCard(artist: artist)
                    }
                }
            }
        }
        .padding(Spacing.lg)
    }
    
    private var allResults: some View {
        VStack(spacing: Spacing.xl) {
            // Songs
            if !songResults.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Songs")
                        .font(Typography.headline)
                        .foregroundColor(Colors.primaryText)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(songResults.prefix(5)) { track in
                            TrackRow(track: track)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    playbackEngine.playTrack(track)
                                }
                        }
                    }
                }
            }
            
            // Albums
            if !albumResults.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Albums")
                        .font(Typography.headline)
                        .foregroundColor(Colors.primaryText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.md) {
                            ForEach(albumResults.prefix(5)) { album in
                                AlbumCard(album: album)
                            }
                        }
                    }
                }
            }
            
            // Artists
            if !artistResults.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Artists")
                        .font(Typography.headline)
                        .foregroundColor(Colors.primaryText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.md) {
                            ForEach(artistResults.prefix(5)) { artist in
                                ArtistCard(artist: artist)
                            }
                        }
                    }
                }
            }
            
            if songResults.isEmpty && albumResults.isEmpty && artistResults.isEmpty {
                emptyView(message: "No results found")
            }
        }
    }
    
    private var songResults: [Track] {
        libraryManager.searchTracks(query: searchText)
    }
    
    private var albumResults: [Album] {
        libraryManager.searchAlbums(query: searchText)
    }
    
    private var artistResults: [Artist] {
        libraryManager.searchArtists(query: searchText)
    }
    
    private func emptyView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "magnifyingglass")
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
