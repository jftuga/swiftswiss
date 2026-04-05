@testable import SwiftSwissLib
import Compression
import XCTest

final class CompressTests: XCTestCase {
    func testLZFSERoundTrip() throws {
        let original = Data("Hello, LZFSE compression world! This is a test of the compression framework.".utf8)
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_LZFSE)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_LZFSE)
        XCTAssertEqual(decompressed, original)
    }

    func testLZ4RoundTrip() throws {
        let original = Data("LZ4 is a fast compression algorithm with lower ratio.".utf8)
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_LZ4)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_LZ4)
        XCTAssertEqual(decompressed, original)
    }

    func testZLIBRoundTrip() throws {
        let original = Data("ZLIB/deflate is widely compatible across platforms.".utf8)
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_ZLIB)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_ZLIB)
        XCTAssertEqual(decompressed, original)
    }

    func testLZMARoundTrip() throws {
        let original = Data("LZMA provides the best compression ratio but is slowest.".utf8)
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_LZMA)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_LZMA)
        XCTAssertEqual(decompressed, original)
    }

    func testCompressionReducesSize() throws {
        // Repetitive data should compress well
        let original = Data(repeating: 0x41, count: 10_000)
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_LZFSE)
        // compressed includes 8-byte header, but should still be much smaller
        XCTAssertTrue(compressed.count < original.count,
                       "Compressed size \(compressed.count) should be < original \(original.count)")
    }

    func testEmptyData() throws {
        let original = Data()
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_LZFSE)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_LZFSE)
        XCTAssertEqual(decompressed, original)
    }

    func testLargeData() throws {
        // 100KB of mixed data
        var original = Data(count: 100_000)
        for i in 0..<original.count {
            original[i] = UInt8(i % 256)
        }
        let compressed = try CompressCommand.compressData(original, algorithm: COMPRESSION_ZLIB)
        let decompressed = try CompressCommand.decompressData(compressed, algorithm: COMPRESSION_ZLIB)
        XCTAssertEqual(decompressed, original)
    }

    func testFileRoundTrip() throws {
        let dir = NSTemporaryDirectory()
        let inputPath = writeTestFile(dir: dir, name: "compress_input.txt",
                                       content: String(repeating: "SwiftSwiss compress test! ", count: 100))
        let compressedPath = (dir as NSString).appendingPathComponent("compressed.lzfse")
        let outputPath = (dir as NSString).appendingPathComponent("decompressed.txt")
        defer {
            try? FileManager.default.removeItem(atPath: inputPath)
            try? FileManager.default.removeItem(atPath: compressedPath)
            try? FileManager.default.removeItem(atPath: outputPath)
        }

        _ = try captureStdout {
            try CompressCommand.run(["-algo", "lzfse", "-in", inputPath, "-out", compressedPath])
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: compressedPath))

        _ = try captureStdout {
            try CompressCommand.run(["-d", "-algo", "lzfse", "-in", compressedPath, "-out", outputPath])
        }

        let original = try String(contentsOfFile: inputPath, encoding: .utf8)
        let restored = try String(contentsOfFile: outputPath, encoding: .utf8)
        XCTAssertEqual(original, restored)
    }
}
