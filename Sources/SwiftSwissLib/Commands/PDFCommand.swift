import Foundation
import PDFKit

public enum PDFCommand {
    public static func run(_ args: [String]) throws {
        var mode = "info"
        var inputPath: String?
        var outputPath: String?
        var pages: String?
        var searchText: String?

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
            case "-pages":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("page range") }
                pages = args[i]
            case "-search":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("search text") }
                searchText = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                if inputPath == nil { inputPath = args[i] }
            }
            i += 1
        }

        guard let path = inputPath else {
            throw SwiftSwissError.missingArgument("PDF file path")
        }

        guard let doc = loadPDF(from: path) else {
            throw SwiftSwissError.operationFailed("cannot open PDF: \(path)")
        }

        switch mode {
        case "info":
            printInfo(doc: doc, path: path)

        case "text":
            let text = try extractText(doc: doc, pageRange: pages)
            print(text)

        case "search":
            guard let query = searchText else {
                throw SwiftSwissError.missingArgument("-search <text>")
            }
            let results = search(doc: doc, query: query)
            if results.isEmpty {
                print("No matches found for: \(query)")
            } else {
                for result in results {
                    print(result)
                }
            }

        case "split":
            guard let outPath = outputPath else {
                throw SwiftSwissError.missingArgument("-out <path>")
            }
            guard let pageRange = pages else {
                throw SwiftSwissError.missingArgument("-pages <range> (e.g., 1-3,5,7-9)")
            }
            let indices = try parsePageRange(pageRange, pageCount: doc.pageCount)
            try split(doc: doc, pageIndices: indices, outputPath: outPath)
            print("Wrote \(indices.count) page(s) → \(outPath)")

        case "merge":
            throw SwiftSwissError.invalidOption(
                "merge requires multiple inputs — use: swiftswiss pdf -mode merge -out merged.pdf file1.pdf file2.pdf ...")

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: info, text, search, split)")
        }
    }

    /// Special handling for merge since it needs multiple input files.
    public static func runMerge(args: [String]) throws {
        var outputPath: String?
        var inputPaths: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-out":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("output path") }
                outputPath = args[i]
            case "-mode", "-m", "-h", "--help":
                i += 1  // skip
            default:
                if !args[i].hasPrefix("-") {
                    inputPaths.append(args[i])
                }
            }
            i += 1
        }

        guard let outPath = outputPath else {
            throw SwiftSwissError.missingArgument("-out <path>")
        }
        guard inputPaths.count >= 2 else {
            throw SwiftSwissError.missingArgument("at least 2 PDF files required for merge")
        }

        try merge(inputPaths: inputPaths, outputPath: outPath)
        print("Merged \(inputPaths.count) PDFs → \(outPath)")
    }

    // MARK: - Load

    public static func loadPDF(from path: String) -> PDFDocument? {
        let url = URL(fileURLWithPath: path)
        return PDFDocument(url: url)
    }

    // MARK: - Info

    public static func printInfo(doc: PDFDocument, path: String) {
        print("File:       \(path)")
        print("Pages:      \(doc.pageCount)")

        if let attrs = doc.documentAttributes {
            if let title = attrs[PDFDocumentAttribute.titleAttribute] as? String, !title.isEmpty {
                print("Title:      \(title)")
            }
            if let author = attrs[PDFDocumentAttribute.authorAttribute] as? String, !author.isEmpty {
                print("Author:     \(author)")
            }
            if let subject = attrs[PDFDocumentAttribute.subjectAttribute] as? String, !subject.isEmpty {
                print("Subject:    \(subject)")
            }
            if let creator = attrs[PDFDocumentAttribute.creatorAttribute] as? String, !creator.isEmpty {
                print("Creator:    \(creator)")
            }
            if let producer = attrs[PDFDocumentAttribute.producerAttribute] as? String, !producer.isEmpty {
                print("Producer:   \(producer)")
            }
            if let keywords = attrs[PDFDocumentAttribute.keywordsAttribute] as? [String], !keywords.isEmpty {
                print("Keywords:   \(keywords.joined(separator: ", "))")
            }
        }

        if let page = doc.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            print("Page size:  \(Int(bounds.width)) x \(Int(bounds.height)) points")
        }

        print("Encrypted:  \(doc.isEncrypted)")
        print("Locked:     \(doc.isLocked)")
    }

    // MARK: - Text extraction

    public static func extractText(doc: PDFDocument, pageRange: String?) throws -> String {
        let indices: [Int]
        if let range = pageRange {
            indices = try parsePageRange(range, pageCount: doc.pageCount)
        } else {
            indices = Array(0..<doc.pageCount)
        }

        var texts: [String] = []
        for idx in indices {
            guard let page = doc.page(at: idx) else { continue }
            if let text = page.string {
                texts.append(text)
            }
        }

        if texts.isEmpty {
            throw SwiftSwissError.operationFailed("no text found in specified pages")
        }
        return texts.joined(separator: "\n\n--- Page break ---\n\n")
    }

    // MARK: - Search

    public static func search(doc: PDFDocument, query: String) -> [String] {
        let selections = doc.findString(query, withOptions: .caseInsensitive)
        var results: [String] = []
        for selection in selections {
            guard let page = selection.pages.first else { continue }
            let pageIndex = doc.index(for: page)
            let context = selection.string ?? query
            results.append("Page \(pageIndex + 1): \(context)")
        }
        return results
    }

    // MARK: - Split (extract pages)

    public static func split(doc: PDFDocument, pageIndices: [Int], outputPath: String) throws {
        let newDoc = PDFDocument()
        for (insertIdx, pageIdx) in pageIndices.enumerated() {
            guard let page = doc.page(at: pageIdx) else {
                throw SwiftSwissError.operationFailed("cannot access page \(pageIdx + 1)")
            }
            newDoc.insert(page, at: insertIdx)
        }

        let url = URL(fileURLWithPath: outputPath)
        guard newDoc.write(to: url) else {
            throw SwiftSwissError.operationFailed("failed to write PDF: \(outputPath)")
        }
    }

    // MARK: - Merge

    public static func merge(inputPaths: [String], outputPath: String) throws {
        let merged = PDFDocument()
        var insertIndex = 0

        for path in inputPaths {
            guard let doc = loadPDF(from: path) else {
                throw SwiftSwissError.operationFailed("cannot open PDF: \(path)")
            }
            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                merged.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }

        let url = URL(fileURLWithPath: outputPath)
        guard merged.write(to: url) else {
            throw SwiftSwissError.operationFailed("failed to write merged PDF: \(outputPath)")
        }
    }

    // MARK: - Page range parsing

    public static func parsePageRange(_ range: String, pageCount: Int) throws -> [Int] {
        var indices: [Int] = []
        let parts = range.split(separator: ",")

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-") {
                let bounds = trimmed.split(separator: "-")
                guard bounds.count == 2,
                      let start = Int(bounds[0]),
                      let end = Int(bounds[1]),
                      start >= 1, end >= start, end <= pageCount else {
                    throw SwiftSwissError.invalidOption("invalid page range: \(trimmed) (document has \(pageCount) pages)")
                }
                indices.append(contentsOf: (start - 1)...(end - 1))
            } else {
                guard let num = Int(trimmed), num >= 1, num <= pageCount else {
                    throw SwiftSwissError.invalidOption("invalid page number: \(trimmed) (document has \(pageCount) pages)")
                }
                indices.append(num - 1)
            }
        }

        guard !indices.isEmpty else {
            throw SwiftSwissError.invalidOption("empty page range")
        }
        return indices
    }

    // MARK: - Help

    static func printHelp() {
        print("""
        Usage: swiftswiss pdf -mode <mode> [options]

        PDF processing: extract text, search, split, merge, and inspect metadata.

        Modes:
          info       Display PDF metadata and page count (default)
          text       Extract text from all or specific pages
          search     Search for text within the PDF
          split      Extract specific pages into a new PDF
          merge      Combine multiple PDFs into one

        Options:
          -mode, -m <mode>      Processing mode (default: info)
          -in <path>            Input PDF file
          -out <path>           Output PDF file (for split/merge)
          -pages <range>        Page range, e.g., 1-3,5,7-9 (for text/split)
          -search <text>        Text to search for (for search mode)
          -h, --help            Show this help

        Examples:
          swiftswiss pdf document.pdf
          swiftswiss pdf -mode text -in document.pdf
          swiftswiss pdf -mode text -in document.pdf -pages 1-3
          swiftswiss pdf -mode search -in document.pdf -search "hello"
          swiftswiss pdf -mode split -in document.pdf -pages 2-5 -out excerpt.pdf
          swiftswiss pdf -mode merge -out combined.pdf file1.pdf file2.pdf

        Frameworks: PDFKit
        """)
    }
}
