import Foundation
import AVFoundation
import SwiftData

class AnimatedArtworkService {
    static let shared = AnimatedArtworkService()
    
    private let baseURL = "https://artwork.m8tec.top/api/v1/artwork"
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Search
    
    func searchArtwork(artist: String, album: String) async throws -> ArtworkSearchResult? {
        // Check cache first
        if let cached = loadCachedSearch(artist: artist, album: album) {
            // Check if cache is still valid (24 hours)
            if let expiryDate = cached.expiryDate, expiryDate > Date() {
                return cached
            }
        }
        
        // Search by artist and album
        let urlString = "\(baseURL)/search?artist=\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&album=\(album.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw ArtworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArtworkError.networkError
        }
        
        if httpResponse.statusCode == 404 {
            // Cache negative result
            cacheNegativeResult(artist: artist, album: album)
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ArtworkError.invalidResponse
        }
        
        let searchResult = ArtworkSearchResult(artist: artist, album: album)
        searchResult.isAvailable = true
        searchResult.animatedURL = json["animated_url"] as? String
        searchResult.staticURL = json["static_url"] as? String
        searchResult.squareURL = json["square_url"] as? String
        searchResult.portraitURL = json["portrait_url"] as? String
        searchResult.appleMusicURL = json["apple_music_url"] as? String
        
        // Cache the result
        cacheSearchResult(searchResult)
        
        return searchResult
    }
    
    func searchArtwork(appleMusicURL: String) async throws -> ArtworkSearchResult? {
        let urlString = "\(baseURL)/url?url=\(appleMusicURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw ArtworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArtworkError.networkError
        }
        
        if httpResponse.statusCode == 404 {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ArtworkError.invalidResponse
        }
        
        // Extract artist and album from response
        let artist = json["artist"] as? String ?? ""
        let album = json["album"] as? String ?? ""
        
        let searchResult = ArtworkSearchResult(artist: artist, album: album)
        searchResult.isAvailable = true
        searchResult.animatedURL = json["animated_url"] as? String
        searchResult.staticURL = json["static_url"] as? String
        searchResult.squareURL = json["square_url"] as? String
        searchResult.portraitURL = json["portrait_url"] as? String
        searchResult.appleMusicURL = appleMusicURL
        
        return searchResult
    }
    
    // MARK: - Caching
    
    private func loadCachedSearch(artist: String, album: String) -> ArtworkSearchResult? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<ArtworkSearchResult>(
            predicate: #Predicate<ArtworkSearchResult> { result in
                result.artist == artist && result.album == album
            }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    private func cacheSearchResult(_ result: ArtworkSearchResult) {
        guard let context = modelContext else { return }
        
        // Set expiry to 24 hours from now
        result.expiryDate = Date().addingTimeInterval(24 * 60 * 60)
        
        context.insert(result)
        try? context.save()
    }
    
    private func cacheNegativeResult(artist: String, album: String) {
        guard let context = modelContext else { return }
        
        let result = ArtworkSearchResult(artist: artist, album: album)
        result.isAvailable = false
        result.expiryDate = Date().addingTimeInterval(6 * 60 * 60) // 6 hours for negative results
        
        context.insert(result)
        try? context.save()
    }
    
    // MARK: - HLS Rendering
    
    func createAnimatedArtworkPlayer(url: URL) -> AVPlayer? {
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        // Configure for looping
        player.actionAtItemEnd = .none
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playerItem.seek(to: .zero)
            player.play()
        }
        
        return player
    }
}

enum ArtworkError: Error {
    case invalidURL
    case networkError
    case invalidResponse
    case noArtworkAvailable
}
