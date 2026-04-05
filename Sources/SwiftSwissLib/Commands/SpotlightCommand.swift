import CoreServices
import Foundation

public enum SpotlightCommand {
    public static func run(_ args: [String]) throws {
        var mode = "name"
        var term: String?
        var limit = 25
        var directory: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-limit":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("limit (integer)")
                }
                limit = v
            case "-dir":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("directory") }
                directory = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                term = args[i]
            }
            i += 1
        }

        guard let searchTerm = term else { throw SwiftSwissError.missingArgument("search term") }

        let queryString: String
        switch mode {
        case "name":
            queryString = "kMDItemDisplayName == '*\(searchTerm)*'cd"
        case "content":
            queryString = "kMDItemTextContent == '*\(searchTerm)*'cd"
        case "kind":
            queryString = "kMDItemKind == '*\(searchTerm)*'cd"
        case "author":
            queryString = "kMDItemAuthors == '*\(searchTerm)*'cd"
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: name, content, kind, author)")
        }

        guard let query = MDQueryCreate(kCFAllocatorDefault, queryString as CFString, nil, nil) else {
            throw SwiftSwissError.operationFailed("failed to create Spotlight query")
        }

        MDQuerySetMaxCount(query, CFIndex(limit))

        if let dir = directory {
            let scopeList = [dir as CFString] as CFArray
            MDQuerySetSearchScope(query, scopeList, 0)
        }

        guard MDQueryExecute(query, CFOptionFlags(kMDQuerySynchronous.rawValue)) else {
            throw SwiftSwissError.operationFailed("Spotlight query failed to execute")
        }

        let count = MDQueryGetResultCount(query)
        if count == 0 {
            print("No results found for: \(searchTerm) (mode: \(mode))")
            return
        }

        print("Found \(count) result(s):")
        for idx in 0..<count {
            guard let rawPtr = MDQueryGetResultAtIndex(query, idx) else { continue }
            let item = Unmanaged<MDItem>.fromOpaque(rawPtr).takeUnretainedValue()

            if let path = MDItemCopyAttribute(item, kMDItemPath) as? String {
                var details: [String] = []

                if let kind = MDItemCopyAttribute(item, kMDItemKind) as? String {
                    details.append(kind)
                }
                if let size = MDItemCopyAttribute(item, kMDItemFSSize) as? Int {
                    details.append(formatBytes(size))
                }

                let suffix = details.isEmpty ? "" : " (\(details.joined(separator: ", ")))"
                print("  \(path)\(suffix)")
            }
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss spotlight [options] <search-term>

        Search the Spotlight index for files.

        Modes:
          name       Search by file name (default)
          content    Search file contents
          kind       Search by file kind (e.g., "PDF Document")
          author     Search by author

        Options:
          -mode <mode>    Search mode (default: name)
          -limit <n>      Maximum results (default: 25)
          -dir <path>     Restrict search to directory
          -h, --help      Show this help

        Frameworks: CoreServices (MDQuery)
        """)
    }
}
