import Foundation
import SwiftData
import AVFoundation

@MainActor
class LyricsManager: ObservableObject {
    static let shared = LyricsManager()
    
    @Published var currentLyrics: LyricsDocument?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var providers: [LyricsProvider] = []
    private var modelContext: ModelContext?
    
    private init() {
        setupProviders()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupProviders() {
        providers = [
            BiniLyricsProvider(),
            MusixmatchLyricsProvider(),
            LRCLIBLyricsProvider()
        ]
        
        // Sort by priority
        providers.sort { $0.priority < $1.priority }
    }
    
    // MARK: - Lyrics Fetching
    
    func fetchLyrics(for track: Track, providerOrder: [String]? = nil) async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        // Check for cached lyrics first
        if let cached = loadCachedLyrics(for: track) {
            currentLyrics = cached
            return
        }
        
        // Check for embedded lyrics
        if track.hasEmbeddedLyrics {
            if let embedded = await loadEmbeddedLyrics(for: track) {
                cacheLyrics(embedded, for: track)
                currentLyrics = embedded
                return
            }
        }
        
        // Try providers in order
        let orderedProviders = providerOrder.map { order in
            providers.filter { order.contains($0.name.lowercased()) }
        } ?? providers
        
        for provider in orderedProviders {
            do {
                let searchResult = try await provider.searchLyrics(
                    track: track.title,
                    artist: track.artist,
                    album: track.album
                )
                
                let lyricsData = try await provider.fetchLyrics(trackID: searchResult.trackID)
                
                // Create and cache lyrics document
                let lyricsDocument = LyricsDocument(
                    trackID: track.id,
                    lyrics: lyricsData.plainLyrics ?? "",
                    type: lyricsData.syncedLyrics != nil ? .lineSynced : .plain,
                    provider: provider.name,
                    source: lyricsData.source
                )
                
                if let syncedLyrics = lyricsData.syncedLyrics {
                    // Store synced lyrics as JSON in the lyrics field
                    if let encoded = try? JSONEncoder().encode(syncedLyrics) {
                        lyricsDocument.lyrics = String(data: encoded, encoding: .utf8) ?? ""
                    }
                }
                
                lyricsDocument.language = lyricsData.language
                
                cacheLyrics(lyricsDocument, for: track)
                currentLyrics = lyricsDocument
                
                return
                
            } catch LyricsProviderError.notFound {
                continue
            } catch LyricsProviderError.serviceUnavailable {
                continue
            } catch {
                print("Provider \(provider.name) failed: \(error)")
                continue
            }
        }
        
        // No lyrics found
        errorMessage = "No lyrics found"
    }

    private func loadEmbeddedLyrics(for track: Track) async -> LyricsDocument? {
        let url = URL(fileURLWithPath: track.fileURL)
        let asset = AVURLAsset(url: url)
        guard let metadata = try? await asset.load(.metadata) else { return nil }

        for item in metadata {
            let identifier = item.identifier?.rawValue.lowercased() ?? ""
            let isLyrics = identifier.contains("lyrics") ||
                (item.keySpace == .id3 && (item.key as? String)?.lowercased() == "uslt")
            guard isLyrics else { continue }

            let text = (try? await item.load(.stringValue)) ??
                (try? await item.load(.dataValue)).flatMap { String(data: $0, encoding: .utf8) }
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            let document = LyricsDocument(
                trackID: track.id,
                lyrics: text,
                type: .plain,
                provider: "Embedded",
                source: "Audio File"
            )
            document.track = track
            return document
        }
        return nil
    }
    
    // MARK: - Caching
    
    private func loadCachedLyrics(for track: Track) -> LyricsDocument? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<LyricsDocument>()
        let lyrics = (try? context.fetch(descriptor)) ?? []
        
        return lyrics.first { $0.trackID == track.id }
    }
    
    private func cacheLyrics(_ lyrics: LyricsDocument, for track: Track) {
        guard let context = modelContext else { return }
        
        lyrics.track = track
        context.insert(lyrics)
        
        try? context.save()
    }
    
    // MARK: - LRC Import
    
    func importLRCFile(url: URL, for track: Track) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = parseLRCLyrics(content)
        
        let lyricsDocument = LyricsDocument(
            trackID: track.id,
            lyrics: content,
            type: .lineSynced,
            provider: "Local",
            source: "LRC File"
        )
        
        lyricsDocument.userEdited = true
        cacheLyrics(lyricsDocument, for: track)
        currentLyrics = lyricsDocument
    }
    
    private func parseLRCLyrics(_ content: String) -> [LyricsLine] {
        let lines = content.components(separatedBy: .newlines)
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
    
    // MARK: - Lyrics Editing
    
    func editLyrics(_ lyrics: String, for track: Track) {
        guard let context = modelContext else { return }
        
        let lyricsDocument = LyricsDocument(
            trackID: track.id,
            lyrics: lyrics,
            type: .plain,
            provider: "User",
            source: "Manual Edit"
        )
        
        lyricsDocument.userEdited = true
        lyricsDocument.track = track
        
        // Delete existing user-edited lyrics
        let descriptor = FetchDescriptor<LyricsDocument>()
        let lyrics = (try? context.fetch(descriptor)) ?? []
        
        if let existing = lyrics.first(where: { $0.trackID == track.id && $0.userEdited == true }) {
            context.delete(existing)
        }
        
        context.insert(lyricsDocument)
        try? context.save()
        
        currentLyrics = lyricsDocument
    }
    
    // MARK: - Parsed Lyrics for Display
    
    func parsedLyrics() -> [LyricsLine]? {
        guard let lyricsDocument = currentLyrics else { return nil }
        
        if lyricsDocument.type == .lineSynced || lyricsDocument.type == .wordSynced {
            return try? JSONDecoder().decode([LyricsLine].self, from: lyricsDocument.lyrics.data(using: .utf8) ?? Data())
        }
        
        return nil
    }
    
    func plainLyrics() -> String? {
        guard let lyricsDocument = currentLyrics else { return nil }
        
        if lyricsDocument.type == .plain {
            return lyricsDocument.lyrics
        }
        
        return nil
    }
}
