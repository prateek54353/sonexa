import Foundation
import CryptoKit
import SwiftData

class LastFmService {
    static let shared = LastFmService()
    
    private let apiKey = Bundle.main.object(forInfoDictionaryKey: "LastFmAPIKey") as? String ?? ""
    private let sharedSecret = Bundle.main.object(forInfoDictionaryKey: "LastFmSharedSecret") as? String ?? ""
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"
    
    private var sessionKey: String?
    private var username: String?
    private var pendingAuthenticationToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    struct Session {
        let username: String
        let sessionKey: String
    }

    func beginAuthentication() async throws -> URL {
        try validateConfiguration()
        let token = try await getAuthToken()
        pendingAuthenticationToken = token
        guard let url = URL(string: "https://www.last.fm/api/auth/?api_key=\(apiKey)&token=\(token)") else {
            throw LastFmError.invalidRequest
        }
        return url
    }

    func completeAuthentication() async throws -> Session {
        try validateConfiguration()
        guard let token = pendingAuthenticationToken else { throw LastFmError.webAuthRequired }
        let params = [
            "api_key": apiKey,
            "method": "auth.getSession",
            "token": token
        ]
        
        let signature = generateSignature(params)
        let urlString = "\(baseURL)?method=auth.getSession&api_key=\(apiKey)&token=\(token)&api_sig=\(signature)&format=json"
        
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
        pendingAuthenticationToken = nil
        
        return Session(username: name, sessionKey: key)
    }
    
    func sessionKeyValue() -> String? { sessionKey }

    func restoreSession(username: String, sessionKey: String) {
        self.username = username.isEmpty ? nil : username
        self.sessionKey = sessionKey.isEmpty ? nil : sessionKey
    }

    private func getAuthToken() async throws -> String {
        let params = ["api_key": apiKey, "method": "auth.getToken"]
        let signature = generateSignature(params)
        let urlString = "\(baseURL)?method=auth.getToken&api_key=\(apiKey)&api_sig=\(signature)&format=json"
        guard let url = URL(string: urlString) else { throw LastFmError.invalidRequest }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = payload["token"] as? String else {
            throw LastFmError.authenticationFailed
        }
        return token
    }

    private func validateConfiguration() throws {
        guard !apiKey.isEmpty,
              !sharedSecret.isEmpty,
              !apiKey.contains("$("),
              !sharedSecret.contains("$(") else { throw LastFmError.missingConfiguration }
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
    case missingConfiguration
}
