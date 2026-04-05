import CryptoKit
import Foundation

public enum HashCommand {
    public static func run(_ args: [String]) throws {
        var algorithm = "sha256"
        var hmacKey: String?
        var files: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-a", "--algorithm":
                i += 1
                guard i < args.count else { throw SwiftSwissError.missingArgument("algorithm value") }
                algorithm = args[i]
            case "-hmac":
                i += 1
                guard i < args.count else { throw SwiftSwissError.missingArgument("HMAC key") }
                hmacKey = args[i]
            case "-h", "--help":
                printHelp()
                return
            default:
                files.append(args[i])
            }
            i += 1
        }

        if files.isEmpty { files = ["-"] }

        for file in files {
            let data = try readInput(from: file == "-" ? nil : file)
            let hex: String

            if let key = hmacKey {
                hex = try computeHMAC(data: data, algorithm: algorithm, key: key)
            } else {
                hex = try computeHash(data: data, algorithm: algorithm)
            }

            let name = file == "-" ? "(stdin)" : file
            print("\(hex)  \(name)")
        }
    }

    public static func computeHash(data: Data, algorithm: String) throws -> String {
        switch algorithm.lowercased() {
        case "sha256":
            return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case "sha384":
            return SHA384.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case "sha512":
            return SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case "insecure-md5":
            return Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        case "insecure-sha1":
            return Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
        default:
            throw SwiftSwissError.invalidOption(
                "unknown algorithm: \(algorithm) (choices: sha256, sha384, sha512, insecure-md5, insecure-sha1)")
        }
    }

    public static func computeHMAC(data: Data, algorithm: String, key: String) throws -> String {
        let symmetricKey = SymmetricKey(data: Data(key.utf8))
        switch algorithm.lowercased() {
        case "sha256":
            return HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
                .map { String(format: "%02x", $0) }.joined()
        case "sha384":
            return HMAC<SHA384>.authenticationCode(for: data, using: symmetricKey)
                .map { String(format: "%02x", $0) }.joined()
        case "sha512":
            return HMAC<SHA512>.authenticationCode(for: data, using: symmetricKey)
                .map { String(format: "%02x", $0) }.joined()
        default:
            throw SwiftSwissError.invalidOption(
                "HMAC not supported for \(algorithm) (choices: sha256, sha384, sha512)")
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss hash [options] [files...]

        Compute cryptographic hashes of files or stdin.

        Options:
          -a, --algorithm <algo>  Hash algorithm (default: sha256)
                                  Choices: sha256, sha384, sha512, insecure-md5, insecure-sha1
          -hmac <key>             Compute HMAC with the given key
          -h, --help              Show this help

        If no files are specified, reads from stdin.

        Frameworks: CryptoKit
        """)
    }
}
