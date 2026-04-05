@testable import SwiftSwissLib
import XCTest

final class EncryptTests: XCTestCase {
    func testAESGCMRoundTrip() throws {
        let original = Data("Hello, encryption world! 🔐".utf8)
        let password = "test-password-123"

        let encrypted = try EncryptCommand.encrypt(data: original, password: password, algorithm: "aesgcm")
        XCTAssertNotEqual(encrypted, original)
        XCTAssertTrue(encrypted.count > original.count) // overhead from salt + algo byte + nonce + tag

        let decrypted = try DecryptCommand.decrypt(data: encrypted, password: password)
        XCTAssertEqual(decrypted, original)
    }

    func testChaChaPolyRoundTrip() throws {
        let original = Data("ChaCha20-Poly1305 test data".utf8)
        let password = "another-password"

        let encrypted = try EncryptCommand.encrypt(data: original, password: password, algorithm: "chachapoly")
        let decrypted = try DecryptCommand.decrypt(data: encrypted, password: password)
        XCTAssertEqual(decrypted, original)
    }

    func testWrongPasswordFails() throws {
        let original = Data("secret message".utf8)
        let encrypted = try EncryptCommand.encrypt(data: original, password: "correct", algorithm: "aesgcm")

        XCTAssertThrowsError(try DecryptCommand.decrypt(data: encrypted, password: "wrong"))
    }

    func testEmptyData() throws {
        let original = Data()
        let password = "pass"
        let encrypted = try EncryptCommand.encrypt(data: original, password: password, algorithm: "aesgcm")
        let decrypted = try DecryptCommand.decrypt(data: encrypted, password: password)
        XCTAssertEqual(decrypted, original)
    }

    func testLargeData() throws {
        let original = Data(repeating: 0x42, count: 1_000_000) // 1MB
        let password = "big-file-pass"
        let encrypted = try EncryptCommand.encrypt(data: original, password: password, algorithm: "aesgcm")
        let decrypted = try DecryptCommand.decrypt(data: encrypted, password: password)
        XCTAssertEqual(decrypted, original)
    }

    func testDifferentEncryptionsProduceDifferentOutput() throws {
        let original = Data("same input".utf8)
        let password = "same-pass"
        let encrypted1 = try EncryptCommand.encrypt(data: original, password: password, algorithm: "aesgcm")
        let encrypted2 = try EncryptCommand.encrypt(data: original, password: password, algorithm: "aesgcm")
        // Different salt each time means different ciphertext
        XCTAssertNotEqual(encrypted1, encrypted2)
    }

    func testTruncatedDataFails() {
        let shortData = Data([0x01, 0x02, 0x03])
        XCTAssertThrowsError(try DecryptCommand.decrypt(data: shortData, password: "pass"))
    }
}
