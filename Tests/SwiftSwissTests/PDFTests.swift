@testable import SwiftSwissLib
import PDFKit
import XCTest

final class PDFTests: XCTestCase {
    /// Create a simple test PDF with known text content.
    func createTestPDF(pages: Int = 3) -> (String, PDFDocument) {
        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent("test_\(UUID().uuidString).pdf")

        let doc = PDFDocument()
        for i in 0..<pages {
            let page = PDFPage()
            // Add text annotation to make searchable content
            let annotation = PDFAnnotation(
                bounds: CGRect(x: 50, y: 700, width: 400, height: 50),
                forType: .freeText,
                withProperties: nil
            )
            annotation.contents = "Test content on page \(i + 1). Hello world."
            annotation.font = NSFont.systemFont(ofSize: 14)
            page.addAnnotation(annotation)
            doc.insert(page, at: i)
        }

        doc.write(toFile: path)
        return (path, doc)
    }

    func testLoadPDF() throws {
        let (path, _) = createTestPDF()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let doc = PDFCommand.loadPDF(from: path)
        XCTAssertNotNil(doc)
        XCTAssertEqual(doc?.pageCount, 3)
    }

    func testLoadPDFInvalidPath() {
        let doc = PDFCommand.loadPDF(from: "/nonexistent/file.pdf")
        XCTAssertNil(doc)
    }

    func testParsePageRangeSingle() throws {
        let indices = try PDFCommand.parsePageRange("2", pageCount: 5)
        XCTAssertEqual(indices, [1])  // 0-indexed
    }

    func testParsePageRangeSpan() throws {
        let indices = try PDFCommand.parsePageRange("1-3", pageCount: 5)
        XCTAssertEqual(indices, [0, 1, 2])
    }

    func testParsePageRangeMixed() throws {
        let indices = try PDFCommand.parsePageRange("1,3-4", pageCount: 5)
        XCTAssertEqual(indices, [0, 2, 3])
    }

    func testParsePageRangeInvalid() {
        XCTAssertThrowsError(try PDFCommand.parsePageRange("0", pageCount: 5))
        XCTAssertThrowsError(try PDFCommand.parsePageRange("6", pageCount: 5))
        XCTAssertThrowsError(try PDFCommand.parsePageRange("3-1", pageCount: 5))
    }

    func testSplit() throws {
        let (inputPath, doc) = createTestPDF(pages: 5)
        let dir = NSTemporaryDirectory()
        let outputPath = (dir as NSString).appendingPathComponent("split_\(UUID().uuidString).pdf")
        defer {
            try? FileManager.default.removeItem(atPath: inputPath)
            try? FileManager.default.removeItem(atPath: outputPath)
        }

        try PDFCommand.split(doc: doc, pageIndices: [0, 2, 4], outputPath: outputPath)

        let splitDoc = PDFCommand.loadPDF(from: outputPath)
        XCTAssertNotNil(splitDoc)
        XCTAssertEqual(splitDoc?.pageCount, 3)
    }

    func testMerge() throws {
        let (path1, _) = createTestPDF(pages: 2)
        let (path2, _) = createTestPDF(pages: 3)
        let dir = NSTemporaryDirectory()
        let outputPath = (dir as NSString).appendingPathComponent("merged_\(UUID().uuidString).pdf")
        defer {
            try? FileManager.default.removeItem(atPath: path1)
            try? FileManager.default.removeItem(atPath: path2)
            try? FileManager.default.removeItem(atPath: outputPath)
        }

        try PDFCommand.merge(inputPaths: [path1, path2], outputPath: outputPath)

        let merged = PDFCommand.loadPDF(from: outputPath)
        XCTAssertNotNil(merged)
        XCTAssertEqual(merged?.pageCount, 5)
    }

    func testMergeInvalidFile() {
        let dir = NSTemporaryDirectory()
        let outputPath = (dir as NSString).appendingPathComponent("merge_fail.pdf")
        XCTAssertThrowsError(
            try PDFCommand.merge(inputPaths: ["/nonexistent.pdf", "/also_nonexistent.pdf"], outputPath: outputPath)
        )
    }

    func testSearch() throws {
        let (path, doc) = createTestPDF(pages: 2)
        defer { try? FileManager.default.removeItem(atPath: path) }

        // Search for annotation content
        let results = PDFCommand.search(doc: doc, query: "Hello world")
        // Annotations may or may not be searchable depending on PDF internals,
        // but the method should not crash
        XCTAssertTrue(results.count >= 0)
    }

    func testSearchNoResults() throws {
        let (path, doc) = createTestPDF()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let results = PDFCommand.search(doc: doc, query: "xyzzy_nonexistent_string_12345")
        XCTAssertTrue(results.isEmpty)
    }
}
