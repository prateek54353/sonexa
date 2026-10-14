import XCTest
@testable import Sonexa
import CryptoKit

final class LastFmTests: XCTestCase {
    
    // MARK: - Signature Generation Tests
    
    func testMD5Hashing() {
        let testString = "test"
        let hash = md5(testString)
        
        XCTAssertEqual(hash.count, 32) // MD5 produces 32-character hex string
        XCTAssertEqual(hash, "098f6bcd4621d373cade4e832627b4f6")
    }
    
    func testSignatureGeneration() {
        let params = [
            "api_key": "test_key",
            "method": "test.method",
            "param1": "value1",
            "param2": "value2"
        ]
        
        let signature = generateSignature(params, secret: "test_secret")
        
        // Signature should be deterministic
        let signature2 = generateSignature(params, secret: "test_secret")
        XCTAssertEqual(signature, signature2)
        
        // Different secrets should produce different signatures
        let signature3 = generateSignature(params, secret: "different_secret")
        XCTAssertNotEqual(signature, signature3)
    }
    
    func testSignatureParameterOrdering() {
        let params1 = [
            "api_key": "test",
            "method": "auth.getSession",
            "token": "abc123"
        ]
        
        let params2 = [
            "method": "auth.getSession",
            "api_key": "test",
            "token": "abc123"
        ]
        
        let signature1 = generateSignature(params1, secret: "secret")
        let signature2 = generateSignature(params2, secret: "secret")
        
        // Signatures should be the same regardless of parameter order
        XCTAssertEqual(signature1, signature2)
    }
    
    // MARK: - Scrobble Eligibility Tests
    
    func testScrobbleEligibility() {
        let track = Track.preview
        track.duration = 240.0 // 4 minutes
        
        // Play for 50% of duration (should be eligible)
        let played50Percent = track.duration * 0.5
        XCTAssertTrue(isScrobbleEligible(track: track, playedDuration: played50Percent, requiredPercent: 50))
        
        // Play for 30% of duration (should not be eligible)
        let played30Percent = track.duration * 0.3
        XCTAssertFalse(isScrobbleEligible(track: track, playedDuration: played30Percent, requiredPercent: 50))
        
        // Play for 2 minutes minimum (should be eligible)
        let played2Minutes = 120.0
        XCTAssertTrue(isScrobbleEligible(track: track, playedDuration: played2Minutes, requiredPercent: 50, minimumSeconds: 120))
    }
    
    func testScrobbleDeduplication() {
        let scrobble1 = PendingScrobble(
            trackTitle: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            timestamp: Date().timeIntervalSince1970,
            duration: 240.0
        )
        
        let scrobble2 = PendingScrobble(
            trackTitle: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            timestamp: Date().timeIntervalSince1970,
            duration: 240.0
        )
        
        // Same track with same timestamp should be considered duplicate
        XCTAssertTrue(isDuplicateScrobble(scrobble1, scrobble2))
        
        // Different timestamp should not be duplicate
        scrobble2.timestamp = Date().timeIntervalSince1970 + 300
        XCTAssertFalse(isDuplicateScrobble(scrobble1, scrobble2))
    }
    
    // MARK: - Helper Functions
    
    private func md5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func generateSignature(_ params: [String: String], secret: String) -> String {
        let sortedKeys = params.keys.sorted()
        var signature = ""
        
        for key in sortedKeys {
            signature += key + params[key]!
        }
        
        signature += secret
        
        return md5(signature)
    }
    
    private func isScrobbleEligible(track: Track, playedDuration: TimeInterval, requiredPercent: Int, minimumSeconds: TimeInterval = 0) -> Bool {
        let percentPlayed = (playedDuration / track.duration) * 100
        let meetsPercent = percentPlayed >= Double(requiredPercent)
        let meetsMinimum = playedDuration >= minimumSeconds
        
        return meetsPercent && meetsMinimum
    }
    
    private func isDuplicateScrobble(_ scrobble1: PendingScrobble, _ scrobble2: PendingScrobble) -> Bool {
        let timeDifference = abs(scrobble1.timestamp - scrobble2.timestamp)
        
        return scrobble1.trackTitle == scrobble2.trackTitle &&
               scrobble1.artist == scrobble2.artist &&
               timeDifference < 60 // Within 1 minute
    }
}
