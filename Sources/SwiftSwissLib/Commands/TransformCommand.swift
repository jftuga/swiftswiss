import Foundation

public enum TransformCommand {
    public static func run(_ args: [String]) throws {
        var mode = "upper"
        var pattern: String?
        var replacement: String?
        var textArgs: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-pattern":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("pattern") }
                pattern = args[i]
            case "-replace":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("replacement") }
                replacement = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                textArgs.append(args[i])
            }
            i += 1
        }

        let input: String
        if textArgs.isEmpty {
            input = try readInputString(from: nil)
        } else {
            input = textArgs.joined(separator: " ")
        }

        let result = try transform(input, mode: mode, pattern: pattern, replacement: replacement)
        print(result, terminator: mode == "count" ? "\n" : (input.hasSuffix("\n") ? "\n" : "\n"))
    }

    public static func transform(
        _ input: String,
        mode: String,
        pattern: String? = nil,
        replacement: String? = nil
    ) throws -> String {
        switch mode {
        case "upper":
            return input.uppercased()
        case "lower":
            return input.lowercased()
        case "capitalize":
            return input.capitalized
        case "reverse":
            return String(input.reversed())
        case "trim":
            return input.trimmingCharacters(in: .whitespacesAndNewlines)
        case "count":
            return count(input)
        case "replace":
            guard let pat = pattern else { throw SwiftSwissError.missingArgument("-pattern") }
            let repl = replacement ?? ""
            let regex = try NSRegularExpression(pattern: pat)
            let range = NSRange(input.startIndex..., in: input)
            return regex.stringByReplacingMatches(in: input, range: range, withTemplate: repl)
        case "base64encode":
            return Data(input.utf8).base64EncodedString()
        case "base64decode":
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = Data(base64Encoded: trimmed),
                  let decoded = String(data: data, encoding: .utf8) else {
                throw SwiftSwissError.operationFailed("invalid base64 input")
            }
            return decoded
        case "hexencode":
            return Data(input.utf8).map { String(format: "%02x", $0) }.joined()
        case "hexdecode":
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            let bytes = try stride(from: 0, to: trimmed.count, by: 2).map { offset -> UInt8 in
                let start = trimmed.index(trimmed.startIndex, offsetBy: offset)
                let end = trimmed.index(start, offsetBy: 2)
                guard let byte = UInt8(trimmed[start..<end], radix: 16) else {
                    throw SwiftSwissError.operationFailed("invalid hex at position \(offset)")
                }
                return byte
            }
            guard let decoded = String(data: Data(bytes), encoding: .utf8) else {
                throw SwiftSwissError.operationFailed("decoded hex is not valid UTF-8")
            }
            return decoded
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: upper, lower, capitalize, reverse, trim, count, replace, base64encode, base64decode, hexencode, hexdecode)")
        }
    }

    public static func count(_ input: String) -> String {
        let lines = input.components(separatedBy: .newlines).count
        let words = input.split { $0.isWhitespace || $0.isNewline }.count
        let chars = input.count
        let bytes = input.utf8.count
        return """
        Characters: \(chars)
        Words:      \(words)
        Lines:      \(lines)
        Bytes:      \(bytes)
        """
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss transform -mode <mode> [options] [text...]

        Transform text input.

        Modes:
          upper          Convert to uppercase
          lower          Convert to lowercase
          capitalize     Capitalize each word
          reverse        Reverse the string
          trim           Trim whitespace
          count          Count characters, words, lines, and bytes
          replace        Regex replace (-pattern and -replace required)
          base64encode   Base64 encode
          base64decode   Base64 decode
          hexencode      Hex encode
          hexdecode      Hex decode

        Options:
          -mode, -m <mode>   Transform mode (default: upper)
          -pattern <regex>   Regex pattern for replace mode
          -replace <string>  Replacement string for replace mode
          -h, --help         Show this help

        If no text arguments are given, reads from stdin.

        Frameworks: Foundation (NSRegularExpression, String)
        """)
    }
}
