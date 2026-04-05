import CoreGraphics
import Foundation
import ImageIO
import Vision

public enum OCRCommand {
    public static func run(_ args: [String]) throws {
        var imagePath: String?
        var language = "en-US"
        var level = "accurate"

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-lang":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("language") }
                language = args[i]
            case "-level":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("level") }
                level = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                imagePath = args[i]
            }
            i += 1
        }

        guard let path = imagePath else { throw SwiftSwissError.missingArgument("image file path") }
        guard let image = loadImage(from: path) else {
            throw SwiftSwissError.operationFailed("cannot load image: \(path)")
        }

        let text = try recognizeText(
            in: image,
            language: language,
            level: level == "fast" ? .fast : .accurate
        )

        if text.isEmpty {
            printError("no text detected in image")
        } else {
            print(text)
        }
    }

    public static func loadImage(from path: String) -> CGImage? {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        return image
    }

    public static func recognizeText(
        in image: CGImage,
        language: String = "en-US",
        level: VNRequestTextRecognitionLevel = .accurate
    ) throws -> String {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = level
        request.recognitionLanguages = [language]
        request.usesLanguageCorrection = true

        try handler.perform([request])

        guard let observations = request.results else { return "" }
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss ocr [options] <image-file>

        Extract text from images using optical character recognition.

        Options:
          -lang <code>    Recognition language (default: en-US)
          -level <level>  Recognition level: accurate, fast (default: accurate)
          -h, --help      Show this help

        Supported formats: PNG, JPEG, TIFF, BMP, GIF, HEIC

        Frameworks: Vision, CoreGraphics, ImageIO
        """)
    }
}
