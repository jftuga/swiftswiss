@testable import SwiftSwissLib
import XCTest

final class GenerateTests: XCTestCase {
    func testPasswordLength() throws {
        let pw = try GenerateCommand.generatePassword(length: 32, charset: "full")
        XCTAssertEqual(pw.count, 32)
    }

    func testPasswordAlphaCharset() throws {
        let pw = try GenerateCommand.generatePassword(length: 100, charset: "alpha")
        let allAlpha = pw.allSatisfy { $0.isLetter }
        XCTAssertTrue(allAlpha)
    }

    func testPasswordNumericCharset() throws {
        let pw = try GenerateCommand.generatePassword(length: 100, charset: "numeric")
        let allDigits = pw.allSatisfy { $0.isNumber }
        XCTAssertTrue(allDigits)
    }

    func testPasswordHexCharset() throws {
        let pw = try GenerateCommand.generatePassword(length: 100, charset: "hex")
        let valid = CharacterSet(charactersIn: "0123456789abcdef")
        let allHex = pw.unicodeScalars.allSatisfy { valid.contains($0) }
        XCTAssertTrue(allHex)
    }

    func testPasswordUniqueness() throws {
        let pw1 = try GenerateCommand.generatePassword(length: 20, charset: "full")
        let pw2 = try GenerateCommand.generatePassword(length: 20, charset: "full")
        XCTAssertNotEqual(pw1, pw2) // Astronomically unlikely to collide
    }

    func testRandomHexLength() throws {
        let hex = try GenerateCommand.generateRandomHex(count: 16)
        XCTAssertEqual(hex.count, 32) // 16 bytes = 32 hex chars
    }

    func testUUIDGeneration() throws {
        let output = try captureStdout {
            try GenerateCommand.run(["-mode", "uuid"])
        }
        let uuid = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // UUID format: 8-4-4-4-12
        XCTAssertNotNil(UUID(uuidString: uuid), "Output should be a valid UUID: \(uuid)")
    }

    func testKeyGeneration() throws {
        let output = try captureStdout {
            try GenerateCommand.run(["-mode", "key", "-length", "256"])
        }
        let hex = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(hex.count, 64) // 256 bits = 32 bytes = 64 hex chars
    }

    func testInvalidCharset() {
        XCTAssertThrowsError(try GenerateCommand.generatePassword(length: 10, charset: "emoji"))
    }
}
