import XCTest
@testable import Sonexa

final class SonexaTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Track Model Tests
    
    func testTrackInitialization() throws {
        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            fileURL: "/path/to/track.mp3",
            fileName: "track.mp3",
            fileSize: 1024 * 1024 * 5,
            fileType: "mp3",
            duration: 240.0
        )
        
        XCTAssertEqual(track.title, "Test Track")
        XCTAssertEqual(track.artist, "Test Artist")
        XCTAssertEqual(track.album, "Test Album")
        XCTAssertEqual(track.duration, 240.0)
        XCTAssertFalse(track.isFavourite)
        XCTAssertEqual(track.playCount, 0)
    }
    
    func testTrackFormattedDuration() throws {
        let track = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            fileURL: "/path",
            fileName: "test.mp3",
            fileSize: 1024,
            fileType: "mp3",
            duration: 245.5
        )
        
        XCTAssertEqual(track.formattedDuration, "4:05")
    }
    
    // MARK: - LRC Parsing Tests
    
    func testLRCParsing() throws {
        let lrcContent = """
        [00:12.34]First line
        [00:45.67]Second line
        [01:23.45]Third line
        """
        
        let lines = parseLRCLyrics(lrcContent)
        
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].text, "First line")
        XCTAssertEqual(lines[0].startTime, 12.34)
        XCTAssertEqual(lines[1].text, "Second line")
        XCTAssertEqual(lines[1].startTime, 45.67)
    }
    
    func testLRCParsingWithMilliseconds() throws {
        let lrcContent = "[00:12.345]Test line"
        let lines = parseLRCLyrics(lrcContent)
        
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "Test line")
        XCTAssertEqual(lines[0].startTime, 12.345)
    }
    
    func testLRCParsingEmptyLines() throws {
        let lrcContent = """
        [00:12.34]
        [00:45.67]Second line
        """
        
        let lines = parseLRCLyrics(lrcContent)
        
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].text, "")
        XCTAssertEqual(lines[1].text, "Second line")
    }
    
    // MARK: - Time Tag Parsing Tests
    
    func testTimeTagParsing() throws {
        XCTAssertEqual(parseTimeTag("00:12.34"), 12.34)
        XCTAssertEqual(parseTimeTag("01:23.45"), 83.45)
        XCTAssertEqual(parseTimeTag("02:34.56"), 154.56)
    }
    
    func testTimeTagParsingInvalid() throws {
        XCTAssertNil(parseTimeTag("invalid"))
        XCTAssertNil(parseTimeTag("12:34")) // Missing decimal
        XCTAssertNil(parseTimeTag(""))
    }
    
    // MARK: - Lyrics Provider Tests
    
    func testLyricsProviderPriority() throws {
        let binilyrics = BiniLyricsProvider()
        let musixmatch = MusixmatchLyricsProvider()
        let lrclib = LRCLIBLyricsProvider()
        
        XCTAssertLessThan(binilyrics.priority, musixmatch.priority)
        XCTAssertLessThan(musixmatch.priority, lrclib.priority)
    }
    
    // MARK: - Playback Queue Tests
    
    func testQueueInitialization() throws {
        let queueItem = QueueItem(order: 0)
        
        XCTAssertNotNil(queueItem.id)
        XCTAssertEqual(queueItem.order, 0)
    }
    
    // MARK: - Playlist Tests
    
    func testPlaylistInitialization() throws {
        let playlist = Playlist(name: "Test Playlist")
        
        XCTAssertEqual(playlist.name, "Test Playlist")
        XCTAssertEqual(playlist.trackCount, 0)
        XCTAssertNotNil(playlist.id)
    }
    
    func testPlaylistItemInitialization() throws {
        let item = PlaylistItem(order: 5)
        
        XCTAssertEqual(item.order, 5)
        XCTAssertNotNil(item.id)
    }
    
    // MARK: - Album Tests
    
    func testAlbumInitialization() throws {
        let album = Album(name: "Test Album", artist: "Test Artist")
        
        XCTAssertEqual(album.name, "Test Album")
        XCTAssertEqual(album.artist, "Test Artist")
        XCTAssertEqual(album.trackCount, 0)
    }
    
    // MARK: - Artist Tests
    
    func testArtistInitialization() throws {
        let artist = Artist(name: "Test Artist")
        
        XCTAssertEqual(artist.name, "Test Artist")
        XCTAssertEqual(artist.trackCount, 0)
        XCTAssertEqual(artist.albumCount, 0)
    }
    
    // MARK: - Helper Functions
    
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
}
