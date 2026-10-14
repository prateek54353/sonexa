import Foundation

class MusixmatchLyricsProvider: LyricsProvider {
    let name = "Musixmatch"
    let priority = 2
    
    private let baseURL = "https://apic-desktop.musixmatch.com/ws/1.1"
    private let appKey = "community-app-key" // Should be configured securely
    
    func searchLyrics(track: String, artist: String, album: String?) async throws -> LyricsSearchResult {
        // Based on Strvm/musicxmatch-api repository
        // Endpoint: track.search
        let query = "\(artist) \(track)"
        let urlString = "\(baseURL)/track.search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&app_key=\(appKey)&page_size=5"
        
        guard let url = URL(string: urlString) else {
            throw LyricsProviderError.invalidResponse
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let body = message["body"] as? [String: Any],
              let trackList = body["track_list"] as? [[String: Any]] else {
            throw LyricsProviderError.invalidResponse
        }
        
        guard let firstTrack = trackList.first,
              let trackData = firstTrack["track"] as? [String: Any],
              let trackID = trackData["track_id"] as? Int,
              let title = trackData["track_name"] as? String,
              let artistName = trackData["artist_name"] as? String else {
            throw LyricsProviderError.notFound
        }
        
        let albumName = trackData["album_name"] as? String
        let duration = trackData["track_length"] as? Double
        let hasLyrics = trackData["has_lyrics"] as? Int == 1
        
        return LyricsSearchResult(
            trackID: String(trackID),
            title: title,
            artist: artistName,
            album: albumName,
            duration: duration,
            hasSyncedLyrics: hasLyrics,
            confidence: 0.8
        )
    }
    
    func fetchLyrics(trackID: String) async throws -> LyricsData {
        // Based on Strvm/musicxmatch-api repository
        // Endpoint: track.lyrics.get
        let urlString = "\(baseURL)/track.lyrics.get?track_id=\(trackID)&app_key=\(appKey)"
        
        guard let url = URL(string: urlString) else {
            throw LyricsProviderError.invalidResponse
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let body = message["body"] as? [String: Any],
              let lyrics = body["lyrics"] as? [String: Any] else {
            throw LyricsProviderError.invalidResponse
        }
        
        let plainLyrics = lyrics["lyrics_body"] as? String
        let lyricsLanguage = lyrics["lyrics_language"] as? String
        
        // Check for synced lyrics
        let syncedLyricsText = lyrics["lyrics_body"] as? String
        var syncedLines: [LyricsLine]? = nil
        
        if let syncedText = syncedLyricsText, syncedText.contains("[") {
            syncedLines = parseLRCLyrics(syncedText)
        }
        
        return LyricsData(
            plainLyrics: plainLyrics?.replacingOccurrences(of: "******* This Lyrics is NOT for Commercial use *******", with: ""),
            syncedLyrics: syncedLines,
            language: lyricsLanguage,
            source: "Musixmatch",
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
