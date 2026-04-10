import Foundation
import UniformTypeIdentifiers

public enum FileTypeCommand {
    public static func run(_ args: [String]) throws {
        var mode = "identify"
        var input: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                input = args[i]
            }
            i += 1
        }

        switch mode {
        case "identify":
            guard let path = input else { throw SwiftSwissError.missingArgument("file path or extension") }
            try identifyFile(path)

        case "mime":
            guard let ext = input else { throw SwiftSwissError.missingArgument("file extension") }
            let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
            if let utType = UTType(filenameExtension: cleanExt) {
                print(utType.preferredMIMEType ?? "unknown")
            } else {
                print("unknown extension: \(cleanExt)")
            }

        case "conforms":
            guard let ext = input else { throw SwiftSwissError.missingArgument("file extension") }
            let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
            guard let utType = UTType(filenameExtension: cleanExt) else {
                throw SwiftSwissError.operationFailed("unknown extension: \(cleanExt)")
            }
            printConformance(utType)

        case "extensions":
            guard let mime = input else { throw SwiftSwissError.missingArgument("MIME type") }
            if let utType = UTType(mimeType: mime) {
                let desc = utType.localizedDescription ?? utType.identifier
                print("Type:       \(desc)")
                print("Identifier: \(utType.identifier)")
                if let ext = utType.preferredFilenameExtension {
                    print("Extension:  .\(ext)")
                }
            } else {
                print("Unknown MIME type: \(mime)")
            }

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: identify, mime, conforms, extensions)")
        }
    }

    static func identifyFile(_ path: String) throws {
        let ext: String
        if FileManager.default.fileExists(atPath: path) {
            ext = (path as NSString).pathExtension
            let attrs = try FileManager.default.attributesOfItem(atPath: path)
            print("File:       \(path)")
            if let size = attrs[.size] as? Int {
                print("Size:       \(formatBytes(size))")
            }
        } else {
            // Treat as extension
            ext = path.hasPrefix(".") ? String(path.dropFirst()) : path
        }

        guard !ext.isEmpty, let utType = UTType(filenameExtension: ext) else {
            print("Type:       unknown")
            return
        }

        print("Type:       \(utType.localizedDescription ?? "unknown")")
        print("Identifier: \(utType.identifier)")
        if let mime = utType.preferredMIMEType {
            print("MIME:       \(mime)")
        }

        var categories: [String] = []
        if utType.conforms(to: .image) { categories.append("Image") }
        if utType.conforms(to: .audiovisualContent) { categories.append("Audio/Video") }
        if utType.conforms(to: .audio) { categories.append("Audio") }
        if utType.conforms(to: .text) { categories.append("Text") }
        if utType.conforms(to: .sourceCode) { categories.append("Source Code") }
        if utType.conforms(to: .executable) { categories.append("Executable") }
        if utType.conforms(to: .archive) { categories.append("Archive") }
        if utType.conforms(to: .pdf) { categories.append("PDF") }
        if utType.conforms(to: .presentation) { categories.append("Presentation") }
        if utType.conforms(to: .spreadsheet) { categories.append("Spreadsheet") }
        if utType.conforms(to: .font) { categories.append("Font") }
        if !categories.isEmpty {
            print("Categories: \(categories.joined(separator: ", "))")
        }
    }

    static func printConformance(_ utType: UTType) {
        print("Type: \(utType.localizedDescription ?? utType.identifier)")
        print("Identifier: \(utType.identifier)")
        print("\nConforms to:")
        for supertype in utType.supertypes.sorted(by: { $0.identifier < $1.identifier }) {
            let desc = supertype.localizedDescription ?? ""
            print("  \(supertype.identifier) — \(desc)")
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss filetype [options] <file-or-extension>

        Identify file types, MIME types, and type conformance.

        Modes:
          identify    Identify a file or extension (default)
          mime        Get MIME type for an extension
          conforms    Show type conformance hierarchy
          extensions  Get extension for a MIME type

        Options:
          -mode, -m <mode>  Mode (default: identify)
          -h, --help      Show this help

        Examples:
          swiftswiss filetype photo.png
          swiftswiss filetype -mode mime .swift
          swiftswiss filetype -mode conforms png
          swiftswiss filetype -mode extensions "application/json"

        Frameworks: UniformTypeIdentifiers
        """)
    }
}
