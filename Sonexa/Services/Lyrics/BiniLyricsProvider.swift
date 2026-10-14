import Foundation

final class BiniLyricsProvider: LyricsProvider {
    let name = "BiniLyrics"
    let priority = 1

    private let searchURL = URL(string: "https://lyrics-api.binimum.org/getLyrics")!
    private let storageURL = URL(string: "https://lyrics-storage.binimum.org/")!
    private var searchResults: [String: SearchResult] = [:]

    func searchLyrics(track: String, artist: String, album: String?) async throws -> LyricsSearchResult {
        var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: "\(artist) - \(track)")]
        guard let url = components.url else { throw LyricsProviderError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("Sonexa/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw LyricsProviderError.networkError(URLError(.badServerResponse)) }
        guard httpResponse.statusCode == 200 else { throw providerError(for: httpResponse.statusCode) }

        let results = try JSONDecoder().decode(SearchResponse.self, from: data).results
        guard let result = results.first(where: { $0.lyricsURL != nil }) else { throw LyricsProviderError.notFound }

        let id = result.id ?? result.isrc ?? UUID().uuidString
        searchResults[id] = result
        return LyricsSearchResult(trackID: id, title: result.trackName, artist: result.artistName, album: result.albumName, duration: result.duration, hasSyncedLyrics: result.timingType != "none", confidence: 0.8)
    }

    func fetchLyrics(trackID: String) async throws -> LyricsData {
        guard let result = searchResults.removeValue(forKey: trackID), let lyricsURL = result.lyricsURL else { throw LyricsProviderError.notFound }
        let url = URL(string: lyricsURL) ?? storageURL.appendingPathComponent(lyricsURL)
        var request = URLRequest(url: url)
        request.setValue("Sonexa/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw LyricsProviderError.networkError(URLError(.badServerResponse)) }
        guard httpResponse.statusCode == 200, let ttml = String(data: data, encoding: .utf8) else { throw LyricsProviderError.serviceUnavailable }

        let lines = parseTTML(ttml)
        guard !lines.isEmpty else { throw LyricsProviderError.notFound }
        return LyricsData(plainLyrics: lines.map(\.text).joined(separator: "\n"), syncedLyrics: lines, language: nil, source: "BiniLyrics", isWordSynced: false)
    }

    private func parseTTML(_ ttml: String) -> [LyricsLine] {
        let pattern = #"<p\b([^>]*)>([\s\S]*?)</p>"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return expression.matches(in: ttml, range: NSRange(ttml.startIndex..., in: ttml)).compactMap { match in
            guard let attributesRange = Range(match.range(at: 1), in: ttml), let bodyRange = Range(match.range(at: 2), in: ttml) else { return nil }
            let attributes = String(ttml[attributesRange])
            guard let start = timestamp(in: attributes, attribute: "begin") else { return nil }
            let text = String(ttml[bodyRange]).replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression).replacingOccurrences(of: "&amp;", with: "&").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return LyricsLine(text: text, startTime: start, endTime: timestamp(in: attributes, attribute: "end"))
        }
    }

    private func timestamp(in attributes: String, attribute: String) -> TimeInterval? {
        let pattern = "\\b\(attribute)=\\\"([^\\\"]+)\\\""
        guard let match = try? NSRegularExpression(pattern: pattern).firstMatch(in: attributes, range: NSRange(attributes.startIndex..., in: attributes)), let range = Range(match.range(at: 1), in: attributes) else { return nil }
        let value = String(attributes[range])
        if value.hasSuffix("ms"), let milliseconds = Double(value.dropLast(2)) { return milliseconds / 1_000 }
        if value.hasSuffix("s"), let seconds = Double(value.dropLast()) { return seconds }
        let parts = value.split(separator: ":").compactMap(Double.init)
        guard !parts.isEmpty else { return nil }
        return parts.reversed().enumerated().reduce(0) { $0 + $1.element * pow(60, Double($1.offset)) }
    }

    private func providerError(for statusCode: Int) -> LyricsProviderError {
        statusCode == 404 ? .notFound : statusCode == 429 ? .rateLimited : .serviceUnavailable
    }
}

private extension BiniLyricsProvider {
    struct SearchResponse: Decodable { let results: [SearchResult] }
    struct SearchResult: Decodable {
        let id: String?
        let trackName: String
        let artistName: String
        let albumName: String?
        let duration: TimeInterval?
        let isrc: String?
        let timingType: String?
        let lyricsURL: String?
        enum CodingKeys: String, CodingKey { case id, isrc, duration; case trackName = "track_name"; case artistName = "artist_name"; case albumName = "album_name"; case timingType = "timing_type"; case lyricsURL = "lyricsUrl" }
    }
}
