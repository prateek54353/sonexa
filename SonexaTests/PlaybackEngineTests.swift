import XCTest
@testable import Sonexa

final class PlaybackEngineTests: XCTestCase {
    
    var playbackEngine: PlaybackEngine!
    
    override func setUpWithError() throws {
        playbackEngine = PlaybackEngine.shared
    }
    
    override func tearDownWithError() throws {
        playbackEngine = nil
    }
    
    // MARK: - State Tests
    
    func testInitialState() {
        XCTAssertFalse(playbackEngine.isPlaying)
        XCTAssertNil(playbackEngine.currentTrack)
        XCTAssertEqual(playbackEngine.currentTime, 0)
        XCTAssertEqual(playbackEngine.duration, 0)
        XCTAssertEqual(playbackEngine.repeatMode, .off)
        XCTAssertEqual(playbackEngine.shuffleMode, .off)
        XCTAssertTrue(playbackEngine.queue.isEmpty)
    }
    
    // MARK: - Repeat Mode Tests
    
    func testRepeatModeToggle() {
        XCTAssertEqual(playbackEngine.repeatMode, .off)
        
        playbackEngine.toggleRepeat()
        XCTAssertEqual(playbackEngine.repeatMode, .all)
        
        playbackEngine.toggleRepeat()
        XCTAssertEqual(playbackEngine.repeatMode, .one)
        
        playbackEngine.toggleRepeat()
        XCTAssertEqual(playbackEngine.repeatMode, .off)
    }
    
    func testRepeatModeDisplayNames() {
        XCTAssertEqual(RepeatMode.off.displayName, "Off")
        XCTAssertEqual(RepeatMode.all.displayName, "All")
        XCTAssertEqual(RepeatMode.one.displayName, "One")
    }
    
    // MARK: - Shuffle Mode Tests
    
    func testShuffleModeToggle() {
        XCTAssertEqual(playbackEngine.shuffleMode, .off)
        
        playbackEngine.toggleShuffle()
        XCTAssertEqual(playbackEngine.shuffleMode, .on)
        
        playbackEngine.toggleShuffle()
        XCTAssertEqual(playbackEngine.shuffleMode, .off)
    }
    
    func testShuffleModeDisplayNames() {
        XCTAssertEqual(ShuffleMode.off.displayName, "Off")
        XCTAssertEqual(ShuffleMode.on.displayName, "On")
    }
    
    // MARK: - Queue Tests
    
    func testSetQueue() {
        let tracks = [
            Track.preview,
            Track(title: "Track 2", artist: "Artist 2", album: "Album 2", fileURL: "/path2", fileName: "track2.mp3", fileSize: 1024, fileType: "mp3", duration: 180.0)
        ]
        
        playbackEngine.setQueue(tracks, startIndex: 0)
        
        XCTAssertEqual(playbackEngine.queue.count, 2)
        XCTAssertEqual(playbackEngine.queueIndex, 0)
    }
    
    func testAddToQueue() {
        let track1 = Track.preview
        let track2 = Track(title: "Track 2", artist: "Artist 2", album: "Album 2", fileURL: "/path2", fileName: "track2.mp3", fileSize: 1024, fileType: "mp3", duration: 180.0)
        
        playbackEngine.setQueue([track1], startIndex: 0)
        playbackEngine.addToQueue([track2])
        
        XCTAssertEqual(playbackEngine.queue.count, 2)
    }
    
    func testClearQueue() {
        let tracks = [Track.preview]
        playbackEngine.setQueue(tracks, startIndex: 0)
        
        playbackEngine.clearQueue()
        
        XCTAssertTrue(playbackEngine.queue.isEmpty)
        XCTAssertEqual(playbackEngine.queueIndex, 0)
    }
    
    func testRemoveFromQueue() {
        let track1 = Track.preview
        let track2 = Track(title: "Track 2", artist: "Artist 2", album: "Album 2", fileURL: "/path2", fileName: "track2.mp3", fileSize: 1024, fileType: "mp3", duration: 180.0)
        let track3 = Track(title: "Track 3", artist: "Artist 3", album: "Album 3", fileURL: "/path3", fileName: "track3.mp3", fileSize: 1024, fileType: "mp3", duration: 200.0)
        
        playbackEngine.setQueue([track1, track2, track3], startIndex: 1)
        playbackEngine.removeFromQueue(at: 0)
        
        XCTAssertEqual(playbackEngine.queue.count, 2)
        XCTAssertEqual(playbackEngine.queueIndex, 0) // Should adjust
    }
    
    // MARK: - Playback Rate Tests
    
    func testSetPlaybackRate() {
        playbackEngine.setPlaybackRate(1.5)
        XCTAssertEqual(playbackEngine.playbackRate, 1.5)
        
        playbackEngine.setPlaybackRate(0.5)
        XCTAssertEqual(playbackEngine.playbackRate, 0.5)
    }
}
