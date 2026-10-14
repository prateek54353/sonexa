import Foundation

class LRCLIBLyricsProvider: LyricsProvider {
    let name = "LRCLIB"
    let priority = 3
    
    private let baseURL = "https://lrclib.net/api"
    
    func searchLyrics(track: String, artist: String, album: String?) async throws -> LyricsSearchResult {
        // Based on lrclib.net/docs
        // Endpoint: GET /api/get?artist_name={artist}&track_name={track}&album_name={album}
        var urlString = "\(baseURL)/get?artist_name=\(artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&track_name=\(track.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let album = album {
            urlString += "&album_name=\(album.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        guard let url = URL(string: urlString) else {
            throw LyricsProviderError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LyricsProviderError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 404 {
            throw LyricsProviderError.notFound
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LyricsProviderError.invalidResponse
        }
        
        guard let trackID = json["id"] as? Int,
              let title = json["trackName"] as? String,
              let artistName = json["artistName"] as? String else {
            throw LyricsProviderError.invalidResponse
        }
        
        let albumName = json["albumName"] as? String
        let duration = json["duration"] as? Double
        let syncedLyrics = json["syncedLyrics"] as? String
        let plainLyrics = json["plainLyrics"] as? String
        
        return LyricsSearchResult(
            trackID: String(trackID),
            title: title,
            artist: artistName,
            album: albumName,
            duration: duration,
            hasSyncedLyrics: syncedLyrics != nil,
            confidence: 0.7
        )
    }
    
    func fetchLyrics(trackID: String) async throws -> LyricsData {
        // Endpoint: GET /api/get/{id}
        let urlString = "\(baseURL)/get/\(trackID)"
        
        guard let url = URL(string: urlString) else {
            throw LyricsProviderError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LyricsProviderError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 404 {
            throw LyricsProviderError.notFound
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LyricsProviderError.invalidResponse
        }
        
        let plainLyrics = json["plainLyrics"] as? String
        let syncedLyricsText = json["syncedLyrics"] as? String
        let lyricsLanguage = json["lang"] as? String
        
        var syncedLines: [LyricsLine]? = nil
        if let syncedText = syncedLyricsText {
            syncedLines = parseLRCLyrics(syncedText)
        }
        
        return LyricsData(
            plainLyrics: plainLyrics,
            syncedLyrics: syncedLines,
            language: lyricsLanguage,
            source: "LRCLIB",
            isWordSynced: false
        )
    }
    
    private func parseLRCLyrics(_ text: String) -> [LyricsLine] {
        let lines = text.components(separatedBy: .newlines)
        var parsedLines: [LyricsLine] = []
        
        for line in lines {
            if line.contains("[") && line.contains("]") {
                let components = line.components(separatedBy: "]")
                if components.count >= 2 {
                    let timeTag = components[0].replacingOccurrences(of: "[", with: "")
                    let text = components[1].trimmingCharacters(in: .whitespaces)
                    
                    if let time = parseTimeTag(timeTag) {
                        parsedLines.append(LyricsLine(text: text, startTime: time))
                    }
                }
            }
        }
        
        return parsedLines
    }
    
    private func parseTimeTag(_ tag: String) -> TimeInterval? {
        let components = tag.components(separatedBy: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]) else {
            return nil
        }
        
        return minutes * 60 + seconds
    }
}
