import Foundation
import SwiftData
import UniformTypeIdentifiers
import PhotosUI

@MainActor
class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var tracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var artists: [Artist] = []
    @Published var playlists: [Playlist] = []
    @Published var isLoading: Bool = false
    @Published var importProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadLibrary()
    }
    
    // MARK: - Library Loading
    
    func loadLibrary() {
        guard let context = modelContext else { return }
        
        let trackDescriptor = FetchDescriptor<Track>()
        tracks = (try? context.fetch(trackDescriptor)) ?? []
        
        let albumDescriptor = FetchDescriptor<Album>()
        albums = (try? context.fetch(albumDescriptor)) ?? []
        
        let artistDescriptor = FetchDescriptor<Artist>()
        artists = (try? context.fetch(artistDescriptor)) ?? []
        
        let playlistDescriptor = FetchDescriptor<Playlist>()
        playlists = (try? context.fetch(playlistDescriptor)) ?? []
    }
    
    // MARK: - File Import
    
    func importFiles(urls: [URL]) async throws {
        isLoading = true
        importProgress = 0.0
        
        guard let context = modelContext else {
            isLoading = false
            throw ImportError.contextNotAvailable
        }
        
        let total = urls.count
        var processed = 0
        
        for url in urls {
            defer {
                processed += 1
                importProgress = Double(processed) / Double(total)
            }
            
            do {
                let track = try await processFile(url: url, context: context)
                context.insert(track)
                
                // Update or create album
                if let album = updateOrCreateAlbum(for: track, context: context) {
                    track.albumEntity = album
                }
                
                // Update or create artist
                if let artist = updateOrCreateArtist(for: track, context: context) {
                    track.artistEntity = artist
                }
            } catch {
                print("Failed to import file: \(url.path), error: \(error)")
            }
        }
        
        try context.save()
        loadLibrary()
        isLoading = false
        importProgress = 0.0
    }
    
    private func processFile(url: URL, context: ModelContext) async throws -> Track {
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Read metadata
        let metadata = try await MetadataReader.readMetadata(from: url)
        
        // Get file attributes
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
        let fileSize = resourceValues.fileSize ?? 0
        let fileName = resourceValues.name ?? url.lastPathComponent
        let fileType = url.pathExtension.lowercased()
        
        // Create track
        let track = Track(
            title: metadata.title ?? fileName,
            artist: metadata.artist ?? "Unknown Artist",
            album: metadata.album ?? "Unknown Album",
            fileURL: url.path,
            fileName: fileName,
            fileSize: Int64(fileSize),
            fileType: fileType,
            duration: metadata.duration ?? 0
        )
        
        // Set additional metadata
        track.albumArtist = metadata.albumArtist
        track.trackNumber = metadata.trackNumber
        track.totalTracks = metadata.totalTracks
        track.discNumber = metadata.discNumber
        track.totalDiscs = metadata.totalDiscs
        track.genre = metadata.genre
        track.year = metadata.year
        track.composer = metadata.composer
        track.bitrate = metadata.bitrate
        track.sampleRate = metadata.sampleRate
        track.channels = metadata.channels
        track.hasEmbeddedLyrics = metadata.hasEmbeddedLyrics
        track.hasEmbeddedArtwork = metadata.hasEmbeddedArtwork
        
        return track
    }
    
    private func updateOrCreateAlbum(for track: Track, context: ModelContext) -> Album? {
        let descriptor = FetchDescriptor<Album>()
        let albums = (try? context.fetch(descriptor)) ?? []
        
        if let existingAlbum = albums.first(where: { $0.name == track.album && $0.artist == track.artist }) {
            if !existingAlbum.tracks.contains(where: { $0.id == track.id }) {
                existingAlbum.tracks.append(track)
            }
            return existingAlbum
        } else {
            let newAlbum = Album(name: track.album, artist: track.artist)
            newAlbum.tracks.append(track)
            context.insert(newAlbum)
            return newAlbum
        }
    }
    
    private func updateOrCreateArtist(for track: Track, context: ModelContext) -> Artist? {
        let descriptor = FetchDescriptor<Artist>()
        let artists = (try? context.fetch(descriptor)) ?? []
        
        if let existingArtist = artists.first(where: { $0.name == track.artist }) {
            if !existingArtist.tracks.contains(where: { $0.id == track.id }) {
                existingArtist.tracks.append(track)
            }
            return existingArtist
        } else {
            let newArtist = Artist(name: track.artist)
            newArtist.tracks.append(track)
            context.insert(newArtist)
            return newArtist
        }
    }
    
    // MARK: - Search
    
    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return tracks }
        
        return tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query) ||
            track.artist.localizedCaseInsensitiveContains(query) ||
            track.album.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchAlbums(query: String) -> [Album] {
        guard !query.isEmpty else { return albums }
        
        return albums.filter { album in
            album.name.localizedCaseInsensitiveContains(query) ||
            album.artist.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchArtists(query: String) -> [Artist] {
        guard !query.isEmpty else { return artists }
        
        return artists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Favourites
    
    func toggleFavourite(_ track: Track) {
        track.isFavourite.toggle()
        
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    var favouriteTracks: [Track] {
        tracks.filter { $0.isFavourite }
    }
    
    // MARK: - Playlists
    
    func createPlaylist(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        
        guard let context = modelContext else { return playlist }
        context.insert(playlist)
        try? context.save()
        
        return playlist
    }
    
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        let item = PlaylistItem(order: playlist.items.count)
        item.track = track
        item.playlist = playlist
        playlist.items.append(item)
        
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    func removeTrackFromPlaylist(_ item: PlaylistItem, playlist: Playlist) {
        if let index = playlist.items.firstIndex(where: { $0.id == item.id }) {
            playlist.items.remove(at: index)
            
            // Reorder remaining items
            for (i, item) in playlist.items.enumerated() {
                item.order = i
            }
        }
        
        guard let context = modelContext else { return }
        try? context.save()
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        
        guard let context = modelContext else { return }
        context.delete(playlist)
        try? context.save()
    }
    
    // MARK: - Rescan
    
    func rescanLibrary() async throws {
        // Collect all file URLs from tracks
        let fileURLs = tracks.compactMap { URL(string: $0.fileURL) }
        
        // Clear existing library
        clearLibrary()
        
        // Re-import files
        try await importFiles(urls: fileURLs)
    }
    
    func importFromAutoImportFolder() async throws {
        let settingsManager = SettingsManager.shared
        guard settingsManager.autoImportFolderEnabled,
              let folderURL = settingsManager.getAutoImportFolderURL() else {
            return
        }
        
        guard folderURL.startAccessingSecurityScopedResource() else {
            print("Failed to access auto-import folder")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }
        
        let audioExtensions = ["mp3", "m4a", "wav", "aiff", "flac", "aac"]
        let audioURLs: [URL] = await Task.detached(priority: .userInitiated) {
            var found: [URL] = []
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
                return found
            }
            
            while let element = enumerator.nextObject() as? URL {
                if let resourceValues = try? element.resourceValues(forKeys: [.isDirectoryKey]),
                   resourceValues.isDirectory == false {
                    if audioExtensions.contains(element.pathExtension.lowercased()) {
                        found.append(element)
                    }
                }
            }
            return found
        }.value
        
        if !audioURLs.isEmpty {
            try await importFiles(urls: audioURLs)
        }
    }
    
    func clearLibrary() {
        guard let context = modelContext else { return }
        
        for track in tracks {
            context.delete(track)
        }
        
        for album in albums {
            context.delete(album)
        }
        
        for artist in artists {
            context.delete(artist)
        }
        
        try? context.save()
        loadLibrary()
    }
}

enum ImportError: Error {
    case contextNotAvailable
    case fileNotAccessible
    case unsupportedFormat
    case metadataReadFailed
}
