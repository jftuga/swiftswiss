@testable import SwiftSwissLib
import XCTest

final class HashTests: XCTestCase {
    func testSHA256KnownValue() throws {
        // SHA-256 of "hello" is well-known
        let data = Data("hello".utf8)
        let hash = try HashCommand.computeHash(data: data, algorithm: "sha256")
        XCTAssertEqual(hash, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }

    func testSHA384() throws {
        let data = Data("hello".utf8)
        let hash = try HashCommand.computeHash(data: data, algorithm: "sha384")
        XCTAssertEqual(hash.count, 96) // 384 bits = 96 hex chars
    }

    func testSHA512() throws {
        let data = Data("hello".utf8)
        let hash = try HashCommand.computeHash(data: data, algorithm: "sha512")
        XCTAssertEqual(hash.count, 128) // 512 bits = 128 hex chars
    }

    func testInsecureMD5() throws {
        let data = Data("hello".utf8)
        let hash = try HashCommand.computeHash(data: data, algorithm: "insecure-md5")
        XCTAssertEqual(hash, "5d41402abc4b2a76b9719d911017c592")
    }

    func testHMACDiffersFromPlainHash() throws {
        let data = Data("test data".utf8)
        let plainHash = try HashCommand.computeHash(data: data, algorithm: "sha256")
        let hmacHash = try HashCommand.computeHMAC(data: data, algorithm: "sha256", key: "secret")
        XCTAssertNotEqual(plainHash, hmacHash)
    }

    func testHMACDeterministic() throws {
        let data = Data("test data".utf8)
        let hash1 = try HashCommand.computeHMAC(data: data, algorithm: "sha256", key: "key")
        let hash2 = try HashCommand.computeHMAC(data: data, algorithm: "sha256", key: "key")
        XCTAssertEqual(hash1, hash2)
    }

    func testHMACDifferentKeys() throws {
        let data = Data("test data".utf8)
        let hash1 = try HashCommand.computeHMAC(data: data, algorithm: "sha256", key: "key1")
        let hash2 = try HashCommand.computeHMAC(data: data, algorithm: "sha256", key: "key2")
        XCTAssertNotEqual(hash1, hash2)
    }

    func testUnknownAlgorithm() {
        let data = Data("hello".utf8)
        XCTAssertThrowsError(try HashCommand.computeHash(data: data, algorithm: "blake2")) { error in
            XCTAssertTrue("\(error)".contains("unknown algorithm"))
        }
    }

    func testHashFromFile() throws {
        let dir = NSTemporaryDirectory()
        let path = writeTestFile(dir: dir, name: "hash_test.txt", content: "hello")
        defer { try? FileManager.default.removeItem(atPath: path) }

        let output = try captureStdout {
            try HashCommand.run(["-a", "sha256", path])
        }
        XCTAssertTrue(output.contains("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"))
        XCTAssertTrue(output.contains(path))
    }
}
