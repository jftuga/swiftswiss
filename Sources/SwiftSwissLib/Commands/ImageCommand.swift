import Accelerate
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageCommand {
    public static func run(_ args: [String]) throws {
        var mode = "info"
        var inputPath: String?
        var outputPath: String?
        var width: Int?
        var height: Int?
        var filterName: String?
        var filterIntensity: Double = 1.0
        var percent: Double?
        var quality: Double?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-in":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("input path") }
                inputPath = args[i]
            case "-out":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("output path") }
                outputPath = args[i]
            case "-width":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("width (integer)")
                }
                width = v
            case "-height":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("height (integer)")
                }
                height = v
            case "-filter":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("filter name") }
                filterName = args[i]
            case "-percent":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("percent (number)")
                }
                guard v > 0 else {
                    throw SwiftSwissError.invalidOption("percent must be greater than 0")
                }
                percent = v
            case "-quality":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("quality (number 0.0-1.0)")
                }
                guard v >= 0.0 && v <= 1.0 else {
                    throw SwiftSwissError.invalidOption("quality must be between 0.0 and 1.0")
                }
                quality = v
            case "-intensity":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("intensity (number)")
                }
                filterIntensity = v
            case "-h", "--help":
                printHelp(); return
            default:
                if inputPath == nil { inputPath = args[i] }
                else if outputPath == nil { outputPath = args[i] }
            }
            i += 1
        }

        switch mode {
        case "info":
            guard let path = inputPath else { throw SwiftSwissError.missingArgument("image file path") }
            try printMetadata(path: path)

        case "resize":
            guard let inPath = inputPath, let outPath = outputPath else {
                throw SwiftSwissError.missingArgument("-in and -out paths required")
            }
            if percent != nil && (width != nil || height != nil) {
                throw SwiftSwissError.invalidOption("-percent cannot be used with -width/-height")
            }
            guard let image = OCRCommand.loadImage(from: inPath) else {
                throw SwiftSwissError.operationFailed("cannot load image: \(inPath)")
            }
            let w: Int
            let h: Int
            if let pct = percent {
                let scale = pct / 100.0
                w = Int(Double(image.width) * scale)
                h = Int(Double(image.height) * scale)
                guard w > 0 && h > 0 else {
                    throw SwiftSwissError.invalidOption("percent too small, resulting dimensions are 0")
                }
            } else {
                guard let uw = width, let uh = height else {
                    throw SwiftSwissError.missingArgument("-width and -height, or -percent required")
                }
                w = uw
                h = uh
            }
            guard let resized = resize(image: image, width: w, height: h) else {
                throw SwiftSwissError.operationFailed("resize failed")
            }
            try saveImage(resized, to: outPath, compressionQuality: quality)
            print("Resized to \(w)x\(h) → \(outPath)")

        case "convert":
            guard let inPath = inputPath, let outPath = outputPath else {
                throw SwiftSwissError.missingArgument("-in and -out paths required")
            }
            guard let image = OCRCommand.loadImage(from: inPath) else {
                throw SwiftSwissError.operationFailed("cannot load image: \(inPath)")
            }
            try saveImage(image, to: outPath, compressionQuality: quality)
            print("Converted → \(outPath)")

        case "filter":
            guard let inPath = inputPath, let outPath = outputPath else {
                throw SwiftSwissError.missingArgument("-in and -out paths required")
            }
            guard let fName = filterName else {
                throw SwiftSwissError.missingArgument("-filter <name> (e.g., sepia, blur, noir, invert, sharpen)")
            }
            guard let image = OCRCommand.loadImage(from: inPath) else {
                throw SwiftSwissError.operationFailed("cannot load image: \(inPath)")
            }
            guard let filtered = applyFilter(image: image, name: fName, intensity: filterIntensity) else {
                throw SwiftSwissError.operationFailed("filter failed: \(fName)")
            }
            try saveImage(filtered, to: outPath, compressionQuality: quality)
            print("Applied \(fName) filter → \(outPath)")

        case "histogram":
            guard let path = inputPath else { throw SwiftSwissError.missingArgument("image file path") }
            guard let image = OCRCommand.loadImage(from: path) else {
                throw SwiftSwissError.operationFailed("cannot load image: \(path)")
            }
            let hist = try computeHistogram(image: image)
            printHistogram(hist)

        case "filters":
            printAvailableFilters()

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: info, resize, convert, filter, filters, histogram)")
        }
    }

    // MARK: - Metadata (ImageIO)

    static func printMetadata(path: String) throws {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            throw SwiftSwissError.operationFailed("cannot open image: \(path)")
        }

        let count = CGImageSourceGetCount(source)
        guard let typeId = CGImageSourceGetType(source) as? String else {
            throw SwiftSwissError.operationFailed("cannot determine image type")
        }

        print("File:   \(path)")
        print("Type:   \(typeId)")
        print("Frames: \(count)")

        if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
            if let w = props[kCGImagePropertyPixelWidth as String] as? Int,
               let h = props[kCGImagePropertyPixelHeight as String] as? Int {
                print("Size:   \(w) x \(h)")
            }
            if let depth = props[kCGImagePropertyDepth as String] as? Int {
                print("Depth:  \(depth) bits")
            }
            if let colorModel = props[kCGImagePropertyColorModel as String] as? String {
                print("Color:  \(colorModel)")
            }
            if let dpiW = props[kCGImagePropertyDPIWidth as String] as? Double {
                print("DPI:    \(Int(dpiW))")
            }
            if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                print("\nEXIF:")
                for (key, value) in exif.sorted(by: { $0.key < $1.key }) {
                    print("  \(key): \(value)")
                }
            }
        }
    }

    // MARK: - Resize (CoreGraphics)

    public static func resize(image: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    // MARK: - Filter (CoreImage)

    public static func applyFilter(image: CGImage, name: String, intensity: Double = 1.0) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let context = CIContext()

        let filterName: String
        var params: [String: Any] = [kCIInputImageKey: ciImage]

        switch name.lowercased() {
        case "sepia":
            filterName = "CISepiaTone"
            params[kCIInputIntensityKey] = intensity
        case "blur":
            filterName = "CIGaussianBlur"
            params["inputRadius"] = intensity * 10
        case "noir":
            filterName = "CIPhotoEffectNoir"
        case "chrome":
            filterName = "CIPhotoEffectChrome"
        case "fade":
            filterName = "CIPhotoEffectFade"
        case "mono":
            filterName = "CIColorMonochrome"
            params["inputColor"] = CIColor(red: 0.7, green: 0.7, blue: 0.7)
            params[kCIInputIntensityKey] = intensity
        case "invert":
            filterName = "CIColorInvert"
        case "sharpen":
            filterName = "CISharpenLuminance"
            params["inputSharpness"] = intensity * 2
        case "vignette":
            filterName = "CIVignette"
            params[kCIInputIntensityKey] = intensity * 2
            params["inputRadius"] = 2.0
        default:
            // Try using the name directly as a CIFilter name
            filterName = name
        }

        guard let filter = CIFilter(name: filterName) else { return nil }
        filter.setDefaults()
        for (key, value) in params {
            filter.setValue(value, forKey: key)
        }

        guard let output = filter.outputImage else { return nil }
        let extent = name.lowercased() == "blur" ? ciImage.extent : output.extent
        return context.createCGImage(output, from: extent)
    }

    // MARK: - Save (ImageIO + UniformTypeIdentifiers)

    public static func saveImage(_ image: CGImage, to path: String, compressionQuality: Double? = nil) throws {
        let url = URL(fileURLWithPath: path) as CFURL
        let ext = (path as NSString).pathExtension.lowercased()

        let utType: UTType
        switch ext {
        case "png": utType = .png
        case "jpg", "jpeg": utType = .jpeg
        case "tiff", "tif": utType = .tiff
        case "gif": utType = .gif
        case "bmp": utType = .bmp
        case "heic": utType = .heic
        default:
            throw SwiftSwissError.invalidOption("unsupported output format: .\(ext)")
        }

        guard let dest = CGImageDestinationCreateWithURL(url, utType.identifier as CFString, 1, nil) else {
            throw SwiftSwissError.operationFailed("cannot create image destination")
        }
        var properties: CFDictionary? = nil
        if let quality = compressionQuality {
            properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        }
        CGImageDestinationAddImage(dest, image, properties)
        guard CGImageDestinationFinalize(dest) else {
            throw SwiftSwissError.operationFailed("failed to write image to \(path)")
        }
    }

    static func printAvailableFilters() {
        print("Built-in filter aliases:")
        let filters = [
            ("sepia", "CISepiaTone", "Warm sepia tone"),
            ("blur", "CIGaussianBlur", "Gaussian blur"),
            ("noir", "CIPhotoEffectNoir", "Black and white noir"),
            ("chrome", "CIPhotoEffectChrome", "Chrome color shift"),
            ("fade", "CIPhotoEffectFade", "Faded vintage look"),
            ("mono", "CIColorMonochrome", "Monochrome tint"),
            ("invert", "CIColorInvert", "Invert all colors"),
            ("sharpen", "CISharpenLuminance", "Sharpen edges"),
            ("vignette", "CIVignette", "Dark edges vignette"),
        ]
        for (alias, ciName, desc) in filters {
            print("  \(alias.padding(toLength: 10, withPad: " ", startingAt: 0)) \(ciName.padding(toLength: 24, withPad: " ", startingAt: 0)) \(desc)")
        }
        print("\nYou can also use any CIFilter name directly (e.g., CIPixellate).")
        print("Total CIFilter types available: \(CIFilter.filterNames(inCategory: nil).count)")
    }

    // MARK: - Histogram (Accelerate / vImage)

    public struct ChannelHistogram {
        public let red: [vImagePixelCount]
        public let green: [vImagePixelCount]
        public let blue: [vImagePixelCount]
        public let alpha: [vImagePixelCount]
    }

    public static func computeHistogram(image: CGImage) throws -> ChannelHistogram {
        // Create an ARGB8888 vImage buffer from the CGImage
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        )!

        var buffer = vImage_Buffer()
        let initErr = vImageBuffer_InitWithCGImage(
            &buffer, &format, nil, image, vImage_Flags(kvImageNoFlags))
        guard initErr == kvImageNoError else {
            throw SwiftSwissError.operationFailed("failed to create vImage buffer (error \(initErr))")
        }
        defer { free(buffer.data) }

        // Compute histogram
        var redHist = [vImagePixelCount](repeating: 0, count: 256)
        var greenHist = [vImagePixelCount](repeating: 0, count: 256)
        var blueHist = [vImagePixelCount](repeating: 0, count: 256)
        var alphaHist = [vImagePixelCount](repeating: 0, count: 256)

        let histErr = redHist.withUnsafeMutableBufferPointer { rBuf in
            greenHist.withUnsafeMutableBufferPointer { gBuf in
                blueHist.withUnsafeMutableBufferPointer { bBuf in
                    alphaHist.withUnsafeMutableBufferPointer { aBuf in
                        // ARGB order: alpha, red, green, blue
                        var histPtrs: [UnsafeMutablePointer<vImagePixelCount>?] = [
                            aBuf.baseAddress, rBuf.baseAddress,
                            gBuf.baseAddress, bBuf.baseAddress,
                        ]
                        return vImageHistogramCalculation_ARGB8888(
                            &buffer, &histPtrs, vImage_Flags(kvImageNoFlags))
                    }
                }
            }
        }
        guard histErr == kvImageNoError else {
            throw SwiftSwissError.operationFailed("histogram calculation failed (error \(histErr))")
        }

        return ChannelHistogram(red: redHist, green: greenHist, blue: blueHist, alpha: alphaHist)
    }

    static func printHistogram(_ hist: ChannelHistogram) {
        let totalPixels = hist.red.reduce(0, +)
        print("Pixel count: \(totalPixels)")
        print()

        for (name, channel) in [("Red", hist.red), ("Green", hist.green), ("Blue", hist.blue)] {
            let maxCount = channel.max() ?? 0
            let nonZeroBins = channel.filter { $0 > 0 }.count
            let weightedSum = channel.enumerated().reduce(0.0) { $0 + Double($1.offset) * Double($1.element) }
            let mean = totalPixels > 0 ? weightedSum / Double(totalPixels) : 0

            print("\(name) channel:")
            print("  Mean intensity: \(String(format: "%.1f", mean)) / 255")
            print("  Non-zero bins:  \(nonZeroBins) / 256")
            print("  Peak bin:       \(channel.firstIndex(of: maxCount) ?? 0) (\(maxCount) pixels)")

            // Print a compact 16-bar visual histogram (group 256 bins into 16)
            let barCount = 16
            let binSize = 256 / barCount
            var grouped = [vImagePixelCount](repeating: 0, count: barCount)
            for i in 0..<barCount {
                for j in 0..<binSize {
                    grouped[i] += channel[i * binSize + j]
                }
            }
            let groupMax = grouped.max() ?? 1
            let barWidth = 40
            print("  Distribution:")
            for i in 0..<barCount {
                let rangeStart = i * binSize
                let rangeEnd = rangeStart + binSize - 1
                let barLen = groupMax > 0 ? Int(Double(grouped[i]) / Double(groupMax) * Double(barWidth)) : 0
                let bar = String(repeating: "█", count: barLen)
                let rangeLabel = "\(String(rangeStart).padding(toLength: 3, withPad: " ", startingAt: 0))-\(String(rangeEnd).padding(toLength: 3, withPad: " ", startingAt: 0))"
                let paddedBar = bar.padding(toLength: barWidth, withPad: " ", startingAt: 0)
                print("    \(rangeLabel) |\(paddedBar)| \(grouped[i])")
            }
            print()
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss image -mode <mode> [options]

        Image processing: resize, convert, filter, and inspect metadata.

        Modes:
          info       Display image metadata (default)
          resize     Resize an image (-width/-height or -percent required)
          convert    Convert between formats (determined by output extension)
          filter     Apply a Core Image filter (-filter required)
          filters    List available filter names
          histogram  Per-channel color histogram (R/G/B intensity distribution)

        Options:
          -mode, -m <mode>      Processing mode (default: info)
          -in <path>            Input image file
          -out <path>           Output image file
          -width <n>            Target width (for resize)
          -height <n>           Target height (for resize)
          -percent <n>          Resize by percentage (e.g., 75, 125)
          -quality <0.0-1.0>    Compression quality for lossy formats (JPEG, HEIC)
          -filter <name>        Filter name (e.g., sepia, blur, noir, invert)
          -intensity <0.0-1.0>  Filter intensity (default: 1.0)
          -h, --help            Show this help

        Frameworks: CoreGraphics, ImageIO, CoreImage, UniformTypeIdentifiers, Accelerate (vImage)
        """)
    }
}
