@testable import SwiftSwissLib
import XCTest

final class JSONTests: XCTestCase {
    let sampleJSON = """
    {"name":"Alice","age":30,"address":{"city":"Portland","state":"OR"},"tags":["swift","cli"]}
    """.data(using: .utf8)!

    func testPrettyPrint() throws {
        let result = try JSONCommand.prettyPrint(sampleJSON)
        XCTAssertTrue(result.contains("\"name\" : \"Alice\""))
        XCTAssertTrue(result.contains("\n")) // should have newlines
    }

    func testCompact() throws {
        let prettyJSON = """
        {
            "name": "Alice",
            "age": 30
        }
        """.data(using: .utf8)!
        let result = try JSONCommand.compact(prettyJSON)
        XCTAssertFalse(result.contains("\n"))
        XCTAssertTrue(result.contains("\"age\":30"))
    }

    func testValidateValid() {
        let result = JSONCommand.validate(sampleJSON)
        XCTAssertEqual(result, "Valid JSON")
    }

    func testValidateInvalid() {
        let invalid = Data("{not json}".utf8)
        let result = JSONCommand.validate(invalid)
        XCTAssertTrue(result.starts(with: "Invalid JSON"))
    }

    func testQuerySimpleKey() throws {
        let result = try JSONCommand.query(sampleJSON, path: "name")
        XCTAssertEqual(result, "Alice")
    }

    func testQueryNestedKey() throws {
        let result = try JSONCommand.query(sampleJSON, path: "address.city")
        XCTAssertEqual(result, "Portland")
    }

    func testQueryArrayIndex() throws {
        let result = try JSONCommand.query(sampleJSON, path: "tags.0")
        XCTAssertEqual(result, "swift")
    }

    func testQueryMissingKey() {
        XCTAssertThrowsError(try JSONCommand.query(sampleJSON, path: "missing"))
    }

    func testQueryNumber() throws {
        let result = try JSONCommand.query(sampleJSON, path: "age")
        XCTAssertEqual(result, "30")
    }
}
