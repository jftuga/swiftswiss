import CryptoKit
import Foundation

public enum GenerateCommand {
    public static func run(_ args: [String]) throws {
        var mode = "password"
        var length = 20
        var charset = "full"
        var count = 1

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-length", "-n":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("length (integer)")
                }
                length = v
            case "-charset":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("charset") }
                charset = args[i]
            case "-count":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("count (integer)")
                }
                count = v
            case "-h", "--help":
                printHelp(); return
            default:
                throw SwiftSwissError.invalidOption("unknown option: \(args[i])")
            }
            i += 1
        }

        switch mode {
        case "password":
            for _ in 0..<count {
                print(try generatePassword(length: length, charset: charset))
            }
        case "uuid":
            for _ in 0..<count {
                print(UUID().uuidString)
            }
        case "bytes":
            print(try generateRandomHex(count: length))
        case "key":
            let keySize: SymmetricKeySize
            switch length {
            case 128: keySize = .bits128
            case 192: keySize = .bits192
            case 256: keySize = .bits256
            default:
                throw SwiftSwissError.invalidOption("key size must be 128, 192, or 256 bits")
            }
            let key = SymmetricKey(size: keySize)
            let hex = key.withUnsafeBytes { Data($0) }.map { String(format: "%02x", $0) }.joined()
            print(hex)
        default:
            throw SwiftSwissError.invalidOption("unknown mode: \(mode) (choices: password, uuid, bytes, key)")
        }
    }

    public static func generatePassword(length: Int, charset: String) throws -> String {
        let chars: String
        switch charset {
        case "alpha":
            chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        case "alphanum":
            chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        case "numeric":
            chars = "0123456789"
        case "hex":
            chars = "0123456789abcdef"
        case "full":
            chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
        default:
            throw SwiftSwissError.invalidOption(
                "unknown charset: \(charset) (choices: alpha, alphanum, numeric, hex, full)")
        }

        let charArray = Array(chars)
        var result = ""
        for _ in 0..<length {
            let index = Int(cryptoRandomUInt32()) % charArray.count
            result.append(charArray[index])
        }
        return result
    }

    public static func generateRandomHex(count: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw SwiftSwissError.operationFailed("failed to generate random bytes")
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func cryptoRandomUInt32() -> UInt32 {
        var value: UInt32 = 0
        _ = SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt32>.size, &value)
        return value
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss generate [options]

        Generate passwords, UUIDs, random bytes, or symmetric keys.

        Options:
          -mode <mode>      Generation mode (default: password)
                            Choices: password, uuid, bytes, key
          -length, -n <n>   Length: chars for password, bytes for bytes,
                            bits (128/192/256) for key (default: 20)
          -charset <set>    Character set for passwords (default: full)
                            Choices: alpha, alphanum, numeric, hex, full
          -count <n>        Number of items to generate (default: 1)
          -h, --help        Show this help

        Frameworks: CryptoKit, Security (SecRandomCopyBytes)
        """)
    }
}
