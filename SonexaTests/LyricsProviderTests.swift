import XCTest
@testable import Sonexa

final class LyricsProviderTests: XCTestCase {
    
    // MARK: - LRCLIB Tests
    
    func testLRCLIBProviderName() {
        let provider = LRCLIBLyricsProvider()
        XCTAssertEqual(provider.name, "LRCLIB")
        XCTAssertEqual(provider.priority, 3)
    }
    
    func testLRCLIBResponseParsing() {
        let mockJSON = """
        {
            "id": 12345,
            "trackName": "Test Track",
            "artistName": "Test Artist",
            "albumName": "Test Album",
            "duration": 240.0,
            "plainLyrics": "Line 1\\nLine 2\\nLine 3",
            "syncedLyrics": "[00:12.34]Line 1\\n[00:45.67]Line 2",
            "lang": "en"
        }
        """
        
        guard let data = mockJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse mock JSON")
            return
        }
        
        XCTAssertEqual(json["trackName"] as? String, "Test Track")
        XCTAssertEqual(json["artistName"] as? String, "Test Artist")
        XCTAssertEqual(json["duration"] as? Double, 240.0)
    }
    
    // MARK: - Musixmatch Tests
    
    func testMusixmatchProviderName() {
        let provider = MusixmatchLyricsProvider()
        XCTAssertEqual(provider.name, "Musixmatch")
        XCTAssertEqual(provider.priority, 2)
    }
    
    func testMusixmatchResponseParsing() {
        let mockJSON = """
        {
            "message": {
                "header": {
                    "status_code": 200
                },
                "body": {
                    "track_list": [
                        {
                            "track": {
                                "track_id": 12345,
                                "track_name": "Test Track",
                                "artist_name": "Test Artist",
                                "album_name": "Test Album",
                                "track_length": 240,
                                "has_lyrics": 1
                            }
                        }
                    ]
                }
            }
        }
        """
        
        guard let data = mockJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let body = message["body"] as? [String: Any],
              let trackList = body["track_list"] as? [[String: Any]],
              let track = trackList.first?["track"] as? [String: Any] else {
            XCTFail("Failed to parse mock JSON")
            return
        }
        
        XCTAssertEqual(track["track_id"] as? Int, 12345)
        XCTAssertEqual(track["track_name"] as? String, "Test Track")
        XCTAssertEqual(track["artist_name"] as? String, "Test Artist")
    }
    
    // MARK: - BiniLyrics Tests
    
    func testBiniLyricsProviderName() {
        let provider = BiniLyricsProvider()
        XCTAssertEqual(provider.name, "BiniLyrics")
        XCTAssertEqual(provider.priority, 1)
    }
    
    // MARK: - Lyrics Data Model Tests
    
    func testLyricsLineModel() {
        let line = LyricsLine(text: "Test line", startTime: 12.34, endTime: 15.67)
        
        XCTAssertEqual(line.text, "Test line")
        XCTAssertEqual(line.startTime, 12.34)
        XCTAssertEqual(line.endTime, 15.67)
        XCTAssertNotNil(line.id)
    }
    
    func testLyricsWordModel() {
        let word = LyricsWord(text: "Test", startTime: 12.34, endTime: 12.56)
        
        XCTAssertEqual(word.text, "Test")
        XCTAssertEqual(word.startTime, 12.34)
        XCTAssertEqual(word.endTime, 12.56)
        XCTAssertNotNil(word.id)
    }
    
    func testLyricsLineEncoding() throws {
        let line = LyricsLine(text: "Test line", startTime: 12.34)
        let encoded = try JSONEncoder().encode(line)
        let decoded = try JSONDecoder().decode(LyricsLine.self, from: encoded)
        
        XCTAssertEqual(line.text, decoded.text)
        XCTAssertEqual(line.startTime, decoded.startTime)
    }
    
    func testLyricsLineArrayEncoding() throws {
        let lines = [
            LyricsLine(text: "Line 1", startTime: 12.34),
            LyricsLine(text: "Line 2", startTime: 45.67)
        ]
        
        let encoded = try JSONEncoder().encode(lines)
        let decoded = try JSONDecoder().decode([LyricsLine].self, from: encoded)
        
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].text, "Line 1")
        XCTAssertEqual(decoded[1].text, "Line 2")
    }
    
    // MARK: - Error Handling Tests
    
    func testLyricsProviderErrorTypes() {
        let error = LyricsProviderError.notFound
        let error2 = LyricsProviderError.networkError(URLError(.notConnectedToInternet))
        let error3 = LyricsProviderError.rateLimited
        let error4 = LyricsProviderError.authenticationFailed
        let error5 = LyricsProviderError.invalidResponse
        let error6 = LyricsProviderError.serviceUnavailable
        
        // Verify error types are distinct
        XCTAssertNotEqual(String(describing: error), String(describing: error2))
    }
}
