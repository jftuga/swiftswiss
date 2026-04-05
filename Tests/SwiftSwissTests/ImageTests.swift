@testable import SwiftSwissLib
import CoreGraphics
import XCTest

final class ImageTests: XCTestCase {
    /// Create a simple test image programmatically.
    func createTestImage(width: Int = 100, height: Int = 100) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Fill with a gradient-like pattern
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(x: width / 2, y: 0, width: width / 2, height: height))

        return context.makeImage()
    }

    func testResize() throws {
        guard let image = createTestImage(width: 200, height: 200) else {
            XCTFail("Failed to create test image"); return
        }

        guard let resized = ImageCommand.resize(image: image, width: 50, height: 50) else {
            XCTFail("Resize returned nil"); return
        }

        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 50)
    }

    func testSaveAndLoadPNG() throws {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent("test_image.png")
        defer { try? FileManager.default.removeItem(atPath: path) }

        try ImageCommand.saveImage(image, to: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))

        guard let loaded = OCRCommand.loadImage(from: path) else {
            XCTFail("Failed to load saved image"); return
        }
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
    }

    func testConvertPNGtoJPEG() throws {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let dir = NSTemporaryDirectory()
        let pngPath = (dir as NSString).appendingPathComponent("convert_test.png")
        let jpgPath = (dir as NSString).appendingPathComponent("convert_test.jpg")
        defer {
            try? FileManager.default.removeItem(atPath: pngPath)
            try? FileManager.default.removeItem(atPath: jpgPath)
        }

        try ImageCommand.saveImage(image, to: pngPath)
        try ImageCommand.saveImage(image, to: jpgPath)

        XCTAssertTrue(FileManager.default.fileExists(atPath: jpgPath))
    }

    func testApplyFilter() throws {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let filtered = ImageCommand.applyFilter(image: image, name: "sepia", intensity: 0.8)
        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered?.width, image.width)
    }

    func testApplyNoirFilter() throws {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let filtered = ImageCommand.applyFilter(image: image, name: "noir")
        XCTAssertNotNil(filtered)
    }

    func testApplyInvertFilter() throws {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let filtered = ImageCommand.applyFilter(image: image, name: "invert")
        XCTAssertNotNil(filtered)
    }

    // MARK: - Histogram (Accelerate / vImage)

    func testHistogramRedImage() throws {
        // Create a solid red image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: 50, height: 50,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { XCTFail("Failed to create context"); return }

        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))

        guard let image = context.makeImage() else { XCTFail("Failed to make image"); return }

        let hist = try ImageCommand.computeHistogram(image: image)
        // Red channel: all pixels at bin 255
        XCTAssertEqual(hist.red[255], 2500) // 50x50
        XCTAssertEqual(hist.red[0], 0)
        // Green channel: all pixels at bin 0
        XCTAssertEqual(hist.green[0], 2500)
        XCTAssertEqual(hist.green[255], 0)
        // Blue channel: all pixels at bin 0
        XCTAssertEqual(hist.blue[0], 2500)
        XCTAssertEqual(hist.blue[255], 0)
    }

    func testHistogramMixedImage() throws {
        // Create an image that is half white, half black
        guard let image = createTestImage(width: 100, height: 100) else {
            XCTFail("Failed to create test image"); return
        }

        let hist = try ImageCommand.computeHistogram(image: image)
        let totalPixels = hist.red.reduce(0, +)
        XCTAssertEqual(totalPixels, 10000) // 100x100
        // Should have non-zero bins (the red/blue halves)
        let nonZeroRed = hist.red.filter { $0 > 0 }.count
        XCTAssertGreaterThan(nonZeroRed, 0)
    }

    func testHistogramOutput() throws {
        guard let image = createTestImage(width: 10, height: 10) else {
            XCTFail("Failed to create test image"); return
        }

        // Save to temp file so we can test via run()
        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent("hist_test.png")
        defer { try? FileManager.default.removeItem(atPath: path) }
        try ImageCommand.saveImage(image, to: path)

        let output = captureStdout {
            try! ImageCommand.run(["-mode", "histogram", "-in", path])
        }
        XCTAssertTrue(output.contains("Pixel count: 100"))
        XCTAssertTrue(output.contains("Red channel:"))
        XCTAssertTrue(output.contains("Green channel:"))
        XCTAssertTrue(output.contains("Blue channel:"))
    }

    func testUnsupportedOutputFormat() {
        guard let image = createTestImage() else { XCTFail("Failed to create test image"); return }

        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent("test.xyz")
        XCTAssertThrowsError(try ImageCommand.saveImage(image, to: path))
    }
}
