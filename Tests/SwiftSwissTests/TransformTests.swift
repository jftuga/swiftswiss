@testable import SwiftSwissLib
import XCTest

final class TransformTests: XCTestCase {
    func testUpper() throws {
        let result = try TransformCommand.transform("hello world", mode: "upper")
        XCTAssertEqual(result, "HELLO WORLD")
    }

    func testLower() throws {
        let result = try TransformCommand.transform("HELLO WORLD", mode: "lower")
        XCTAssertEqual(result, "hello world")
    }

    func testCapitalize() throws {
        let result = try TransformCommand.transform("hello world", mode: "capitalize")
        XCTAssertEqual(result, "Hello World")
    }

    func testReverse() throws {
        let result = try TransformCommand.transform("abcdef", mode: "reverse")
        XCTAssertEqual(result, "fedcba")
    }

    func testTrim() throws {
        let result = try TransformCommand.transform("  hello  \n", mode: "trim")
        XCTAssertEqual(result, "hello")
    }

    func testCount() throws {
        let result = try TransformCommand.transform("hello world", mode: "count")
        XCTAssertTrue(result.contains("Characters: 11"))
        XCTAssertTrue(result.contains("Words:      2"))
        XCTAssertTrue(result.contains("Bytes:      11"))
    }

    func testRegexReplace() throws {
        let result = try TransformCommand.transform(
            "foo123bar456", mode: "replace", pattern: "[0-9]+", replacement: "#")
        XCTAssertEqual(result, "foo#bar#")
    }

    func testBase64RoundTrip() throws {
        let encoded = try TransformCommand.transform("Hello, World!", mode: "base64encode")
        XCTAssertEqual(encoded, "SGVsbG8sIFdvcmxkIQ==")
        let decoded = try TransformCommand.transform(encoded, mode: "base64decode")
        XCTAssertEqual(decoded, "Hello, World!")
    }

    func testHexRoundTrip() throws {
        let encoded = try TransformCommand.transform("ABC", mode: "hexencode")
        XCTAssertEqual(encoded, "414243")
        let decoded = try TransformCommand.transform(encoded, mode: "hexdecode")
        XCTAssertEqual(decoded, "ABC")
    }

    func testInvalidBase64() {
        XCTAssertThrowsError(try TransformCommand.transform("!!!not-base64!!!", mode: "base64decode"))
    }

    func testUnknownMode() {
        XCTAssertThrowsError(try TransformCommand.transform("hello", mode: "nonexistent"))
    }
}
