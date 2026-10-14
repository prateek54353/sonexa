import Foundation
import CryptoKit
import SwiftData

class LastFmService {
    static let shared = LastFmService()
    
    private let apiKey = "YOUR_API_KEY" // Should be configured securely
    private let sharedSecret = "YOUR_SHARED_SECRET" // Should be configured securely
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"
    
    private var sessionKey: String?
    private var username: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func authenticate(username: String, password: String) async throws -> Bool {
        // Get auth token
        let token = try await getAuthToken()
        
        // Get session
        let params = [
            "api_key": apiKey,
            "method": "auth.getSession",
            "token": token,
            "username": username
        ]
        
        let signature = generateSignature(params)
        let urlString = "\(baseURL)?method=auth.getSession&api_key=\(apiKey)&token=\(token)&username=\(username)&api_sig=\(signature)&format=json"
        
        guard let url = URL(string: urlString) else {
            throw LastFmError.invalidRequest
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let session = json["session"] as? [String: Any],
              let key = session["key"] as? String,
              let name = session["name"] as? String else {
            throw LastFmError.authenticationFailed
        }
        
        self.sessionKey = key
        self.username = name
        
        return true
    }
    
    private func getAuthToken() async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let signature = md5(apiKey + sharedSecret + timestamp)
        
        let urlString = "https://www.last.fm/api/auth/?api_key=\(apiKey)&token=\(signature)&api_sig=\(signature)"
        
        // Note: This requires user interaction in a web view
        // For now, we'll return a placeholder
        throw LastFmError.webAuthRequired
    }
    
    // MARK: - Now Playing
    
    func updateNowPlaying(track: Track) async throws {
        guard let sessionKey = sessionKey else {
            throw LastFmError.notAuthenticated
        }
        
        let params = [
            "api_key": apiKey,
            "method": "track.updateNowPlaying",
            "sk": sessionKey,
            "artist": track.artist,
            "track": track.title,
            "album": track.album,
            "duration": String(Int(track.duration)),
            "timestamp": String(Int(Date().timeIntervalSince1970))
        ]
        
        let signature = generateSignature(params)
        
        // POST request required
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = ""
        for (key, value) in params {
            body += "\(key)=\(value)&"
        }
        body += "api_sig=\(signature)"
        
        request.httpBody = body.data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LastFmError.requestFailed
        }
    }
    
    // MARK: - Scrobbling
    
    func scrobble(track: Track, timestamp: TimeInterval) async throws {
        guard let sessionKey = sessionKey else {
            throw LastFmError.notAuthenticated
        }
        
        let params = [
            "api_key": apiKey,
            "method": "track.scrobble",
            "sk": sessionKey,
            "artist": track.artist,
            "track": track.title,
            "album": track.album,
            "timestamp": String(Int(timestamp)),
            "duration": String(Int(track.duration))
        ]
        
        let signature = generateSignature(params)
        
        // POST request required
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var body = ""
        for (key, value) in params {
            body += "\(key)=\(value)&"
        }
        body += "api_sig=\(signature)"
        
        request.httpBody = body.data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LastFmError.requestFailed
        }
    }
    
    // MARK: - Queue Management
    
    func queueScrobble(track: Track, timestamp: TimeInterval, context: ModelContext) {
        let pendingScrobble = PendingScrobble(
            trackTitle: track.title,
            artist: track.artist,
            album: track.album,
            timestamp: timestamp,
            duration: track.duration
        )
        
        context.insert(pendingScrobble)
        try? context.save()
    }
    
    func processPendingScrobbles(context: ModelContext) async {
        let descriptor = FetchDescriptor<PendingScrobble>()
        guard let pending = try? context.fetch(descriptor) else { return }
        
        for pendingScrobble in pending {
            do {
                let timestamp = pendingScrobble.timestamp
                
                // Create a temporary track for scrobbling
                let tempTrack = Track(
                    title: pendingScrobble.trackTitle,
                    artist: pendingScrobble.artist,
                    album: pendingScrobble.album ?? "",
                    fileURL: "",
                    fileName: "",
                    fileSize: 0,
                    fileType: "",
                    duration: pendingScrobble.duration
                )
                
                try await self.scrobble(track: tempTrack, timestamp: timestamp)
                
                context.delete(pendingScrobble)
                try? context.save()
                
            } catch {
                pendingScrobble.retryCount += 1
                
                if pendingScrobble.retryCount > 5 {
                    context.delete(pendingScrobble)
                }
                
                try? context.save()
            }
        }
    }
    
    // MARK: - Signature Generation
    
    private func generateSignature(_ params: [String: String]) -> String {
        let sortedKeys = params.keys.sorted()
        var signature = ""
        
        for key in sortedKeys {
            signature += key + params[key]!
        }
        
        signature += sharedSecret
        
        return md5(signature)
    }
    
    private func md5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

enum LastFmError: Error {
    case notAuthenticated
    case authenticationFailed
    case webAuthRequired
    case invalidRequest
    case requestFailed
    case rateLimited
}
