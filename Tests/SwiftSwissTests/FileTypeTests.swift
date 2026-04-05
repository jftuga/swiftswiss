@testable import SwiftSwissLib
import XCTest

final class FileTypeTests: XCTestCase {
    func testIdentifyPNG() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "identify", ".png"])
        }
        XCTAssertTrue(output.contains("PNG") || output.contains("png"))
        XCTAssertTrue(output.contains("Image"))
    }

    func testIdentifySwift() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "identify", ".swift"])
        }
        XCTAssertTrue(output.contains("Swift") || output.contains("swift") || output.contains("Source"))
    }

    func testMIMETypeJSON() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "mime", ".json"])
        }
        XCTAssertTrue(output.contains("application/json"))
    }

    func testMIMTypeJPEG() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "mime", ".jpg"])
        }
        XCTAssertTrue(output.contains("image/jpeg"))
    }

    func testMIMETypePDF() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "mime", ".pdf"])
        }
        XCTAssertTrue(output.contains("application/pdf"))
    }

    func testConformsPNG() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "conforms", "png"])
        }
        XCTAssertTrue(output.contains("public.image"))
    }

    func testExtensionsFromMIME() throws {
        let output = try captureStdout {
            try FileTypeCommand.run(["-mode", "extensions", "text/html"])
        }
        XCTAssertTrue(output.contains("html"))
    }
}
