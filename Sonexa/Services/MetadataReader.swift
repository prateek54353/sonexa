import Foundation
import AVFoundation

struct TrackMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var albumArtist: String?
    var trackNumber: Int?
    var totalTracks: Int?
    var discNumber: Int?
    var totalDiscs: Int?
    var genre: String?
    var year: Int?
    var composer: String?
    var duration: TimeInterval?
    var bitrate: Int?
    var sampleRate: Int?
    var channels: Int?
    var hasEmbeddedLyrics: Bool = false
    var hasEmbeddedArtwork: Bool = false
    var artwork: Data?
}

class MetadataReader {
    static func readMetadata(from url: URL) async throws -> TrackMetadata {
        let asset = AVAsset(url: url)
        
        // Get duration
        let duration = try await asset.load(.duration).seconds
        
        // Get metadata
        let metadata = try await asset.load(.metadata)
        
        var trackMetadata = TrackMetadata(duration: duration)
        
        for item in metadata {
            guard let key = item.commonKey?.rawValue else { continue }
            
            switch key {
            case "title":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.title = value
                }
                
            case "artist":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.artist = value
                }
                
            case "albumName":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.album = value
                }
                
            case "albumArtist":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.albumArtist = value
                }
                
            case "trackNumber":
                if let value = item.numberValue {
                    trackMetadata.trackNumber = value.intValue
                }
                
            case "discNumber":
                if let value = item.numberValue {
                    trackMetadata.discNumber = value.intValue
                }
                
            case "genre":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.genre = value
                }
                
            case "creationDate":
                if let dateString = try? await item.load(.stringValue),
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    trackMetadata.year = Calendar.current.component(.year, from: date)
                }
                
            case "creator":
                if let value = try? await item.load(.stringValue) {
                    trackMetadata.composer = value
                }
                
            default:
                break
            }
        }
        
        // Extract artwork
        let artworkItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtwork)
        if let artworkItem = artworkItems.first,
           let artworkData = try? await artworkItem.load(.dataValue) {
            trackMetadata.artwork = artworkData
            trackMetadata.hasEmbeddedArtwork = true
        }
        
        // Extract lyrics (embedded) - use robust filter
        let lyricsItems = metadata.filter { item in
            if let id = item.identifier?.rawValue.lowercased(), id.contains("lyrics") { return true }
            if item.keySpace == .id3, let key = item.key as? String, key.lowercased() == "uslt" { return true }
            return false
        }
        if !lyricsItems.isEmpty {
            trackMetadata.hasEmbeddedLyrics = true
        }
        
        // Get audio format info
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
            let formatDescriptions = try await audioTrack.load(.formatDescriptions)
            
            if let formatDescription = formatDescriptions.first {
                let audioStreamBasicDescription = formatDescription.formatDescription?.audioStreamBasicDescription
                
                if let asbd = audioStreamBasicDescription {
                    trackMetadata.sampleRate = Int(asbd.mSampleRate)
                    trackMetadata.channels = Int(asbd.mChannelsPerFrame)
                }
            }
        }
        
        // Estimate bitrate from file size and duration
        if let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = resourceValues.fileSize {
            let bitrate = Int((Double(fileSize) * 8) / duration)
            trackMetadata.bitrate = bitrate
        }
        
        return trackMetadata
    }
    
    static func writeMetadata(to url: URL, metadata: TrackMetadata) async throws {
        // Note: AVFoundation does not support writing metadata directly.
        // This would require a third-party library like ID3Tag framework or custom implementation.
        // For now, we'll throw an error indicating this limitation.
        throw MetadataError.writeNotSupported
    }
}

enum MetadataError: Error {
    case fileNotAccessible
    case invalidFormat
    case readFailed
    case writeNotSupported
}
