@testable import SwiftSwissLib
import XCTest

final class TimeTests: XCTestCase {
    func testParseDateISO8601() throws {
        let date = try TimeCommand.parseDate("2024-01-15T12:30:00Z")
        let epoch = Int(date.timeIntervalSince1970)
        // 2024-01-15T12:30:00Z = 1705321800
        XCTAssertEqual(epoch, 1705321800)
    }

    func testParseDateYMD() throws {
        let date = try TimeCommand.parseDate("2024-01-15", timezone: TimeZone(identifier: "UTC")!)
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
    }

    func testParseDateWithFormat() throws {
        let date = try TimeCommand.parseDate("15-Jan-2024", format: "dd-MMM-yyyy", timezone: TimeZone(identifier: "UTC")!)
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
    }

    func testParseDateInvalidFails() {
        XCTAssertThrowsError(try TimeCommand.parseDate("not-a-date"))
    }

    func testFormatDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let result = TimeCommand.formatDate(date, format: "yyyy-MM-dd", timezone: TimeZone(identifier: "UTC")!)
        XCTAssertEqual(result, "1970-01-01")
    }

    func testNowCommand() throws {
        let output = try captureStdout {
            try TimeCommand.run(["-mode", "now"])
        }
        XCTAssertTrue(output.contains("ISO 8601"))
        XCTAssertTrue(output.contains("Unix"))
        XCTAssertTrue(output.contains("Timezone"))
    }

    func testFromEpoch() throws {
        let output = try captureStdout {
            try TimeCommand.run(["-mode", "fromepoch", "-tz", "UTC", "0"])
        }
        XCTAssertTrue(output.contains("1970"))
    }
}
