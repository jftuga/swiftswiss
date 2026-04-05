import Compression
import Foundation

public enum CompressCommand {
    public static func run(_ args: [String]) throws {
        var decompress = false
        var algo = "lzfse"
        var inputPath: String?
        var outputPath: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-d", "--decompress":
                decompress = true
            case "-algo":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("algorithm") }
                algo = args[i]
            case "-in":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("input path") }
                inputPath = args[i]
            case "-out":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("output path") }
                outputPath = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                if inputPath == nil { inputPath = args[i] }
                else if outputPath == nil { outputPath = args[i] }
            }
            i += 1
        }

        guard let inPath = inputPath else { throw SwiftSwissError.missingArgument("input file") }
        guard let outPath = outputPath else { throw SwiftSwissError.missingArgument("output file") }

        let algorithm = try resolveAlgorithm(algo)
        let inputData = try Data(contentsOf: URL(fileURLWithPath: inPath))

        let result: Data
        if decompress {
            result = try decompressData(inputData, algorithm: algorithm)
        } else {
            result = try compressData(inputData, algorithm: algorithm)
        }

        try result.write(to: URL(fileURLWithPath: outPath))

        let action = decompress ? "Decompressed" : "Compressed"
        let ratio = inputData.count > 0 ? Double(result.count) / Double(inputData.count) * 100 : 0
        print("\(action) \(formatBytes(inputData.count)) → \(formatBytes(result.count)) (\(String(format: "%.1f%%", ratio)), \(algo))")
    }

    static func resolveAlgorithm(_ name: String) throws -> compression_algorithm {
        switch name.lowercased() {
        case "lzfse": return COMPRESSION_LZFSE
        case "lz4": return COMPRESSION_LZ4
        case "zlib": return COMPRESSION_ZLIB
        case "lzma": return COMPRESSION_LZMA
        default:
            throw SwiftSwissError.invalidOption(
                "unknown algorithm: \(name) (choices: lzfse, lz4, zlib, lzma)")
        }
    }

    public static func compressData(_ data: Data, algorithm: compression_algorithm) throws -> Data {
        // Store original size as 8-byte header for decompression
        var originalSize = UInt64(data.count)
        var result = Data(bytes: &originalSize, count: 8)

        // Empty data: just the header
        guard !data.isEmpty else { return result }

        // Allocate destination buffer (worst case: slightly larger than input)
        let destinationCapacity = max(data.count * 2, 4096)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationCapacity)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { sourcePtr -> Int in
            guard let baseAddress = sourcePtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_encode_buffer(
                destinationBuffer, destinationCapacity,
                baseAddress, data.count,
                nil,
                algorithm
            )
        }

        guard compressedSize > 0 else {
            throw SwiftSwissError.operationFailed("compression failed")
        }

        result.append(Data(bytes: destinationBuffer, count: compressedSize))
        return result
    }

    public static func decompressData(_ data: Data, algorithm: compression_algorithm) throws -> Data {
        guard data.count >= 8 else {
            throw SwiftSwissError.operationFailed("compressed data is too short")
        }

        // Read original size from 8-byte header
        let originalSize = data.withUnsafeBytes { ptr in
            ptr.load(as: UInt64.self)
        }

        let compressedData = data[8...]

        // Empty original data: return empty
        guard originalSize > 0 else { return Data() }

        let destinationCapacity = Int(originalSize)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationCapacity)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = compressedData.withUnsafeBytes { sourcePtr -> Int in
            guard let baseAddress = sourcePtr.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(
                destinationBuffer, destinationCapacity,
                baseAddress, compressedData.count,
                nil,
                algorithm
            )
        }

        guard decompressedSize > 0 else {
            throw SwiftSwissError.operationFailed("decompression failed")
        }

        return Data(bytes: destinationBuffer, count: decompressedSize)
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss compress [options] -in <file> -out <file>

        Compress or decompress files.

        Options:
          -algo <algorithm>   Compression algorithm (default: lzfse)
                              Choices: lzfse, lz4, zlib, lzma
          -d, --decompress    Decompress instead of compress
          -in <path>          Input file
          -out <path>         Output file
          -h, --help          Show this help

        Notes:
          LZFSE — Apple's modern algorithm, best for most use cases
          LZ4   — Very fast, lower compression ratio
          ZLIB  — Widely compatible (deflate)
          LZMA  — Best compression ratio, slowest

        Frameworks: Compression
        """)
    }
}
