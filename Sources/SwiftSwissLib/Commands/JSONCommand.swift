import Foundation

public enum JSONCommand {
    public static func run(_ args: [String]) throws {
        var mode = "pretty"
        var queryPath: String?
        var filePath: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-query", "-q":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("query path") }
                queryPath = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                filePath = args[i]
            }
            i += 1
        }

        let data = try readInput(from: filePath)

        switch mode {
        case "pretty":
            print(try prettyPrint(data))
        case "compact":
            print(try compact(data))
        case "validate":
            print(validate(data))
        case "query":
            guard let path = queryPath else {
                throw SwiftSwissError.missingArgument("-query <path> is required for query mode")
            }
            let result = try query(data, path: path)
            print(result)
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: pretty, compact, validate, query)")
        }
    }

    public static func prettyPrint(_ data: Data) throws -> String {
        let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let pretty = try JSONSerialization.data(
            withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        guard let str = String(data: pretty, encoding: .utf8) else {
            throw SwiftSwissError.operationFailed("failed to encode JSON as UTF-8")
        }
        return str
    }

    public static func compact(_ data: Data) throws -> String {
        let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let compactData = try JSONSerialization.data(
            withJSONObject: obj, options: [.sortedKeys, .withoutEscapingSlashes])
        guard let str = String(data: compactData, encoding: .utf8) else {
            throw SwiftSwissError.operationFailed("failed to encode JSON as UTF-8")
        }
        return str
    }

    public static func validate(_ data: Data) -> String {
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            return "Valid JSON"
        } catch {
            return "Invalid JSON: \(error.localizedDescription)"
        }
    }

    public static func query(_ data: Data, path: String) throws -> String {
        let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        let components = path.split(separator: ".").map(String.init)

        var current: Any = obj
        for component in components {
            if let dict = current as? [String: Any] {
                guard let next = dict[component] else {
                    throw SwiftSwissError.operationFailed("key not found: \(component)")
                }
                current = next
            } else if let arr = current as? [Any], let index = Int(component) {
                guard index >= 0, index < arr.count else {
                    throw SwiftSwissError.operationFailed("index out of bounds: \(index)")
                }
                current = arr[index]
            } else {
                throw SwiftSwissError.operationFailed("cannot traverse into \(type(of: current)) with key: \(component)")
            }
        }

        if let jsonObj = current as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "\(current)"
        } else if let jsonArr = current as? [Any] {
            let data = try JSONSerialization.data(withJSONObject: jsonArr, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "\(current)"
        } else {
            return "\(current)"
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss json [options] [file]

        Process JSON data.

        Modes:
          pretty     Pretty-print JSON with indentation (default)
          compact    Compact JSON to a single line
          validate   Check if input is valid JSON
          query      Query a value by dot-notation path

        Options:
          -mode <mode>    Processing mode (default: pretty)
          -query, -q <path>  Dot-notation path for query mode (e.g., "users.0.name")
          -h, --help      Show this help

        If no file is specified, reads from stdin.

        Frameworks: Foundation (JSONSerialization)
        """)
    }
}
