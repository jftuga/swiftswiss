import CryptoKit
import Foundation

// File format: [salt:32][algo:1][sealed box combined (nonce + ciphertext + tag)]
// algo byte: 0x01 = AES-GCM, 0x02 = ChaChaPoly

public enum EncryptCommand {
    static let saltSize = 32

    public static func run(_ args: [String]) throws {
        var inputPath: String?
        var outputPath: String?
        var algo = "aesgcm"
        var password: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-in":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("input path") }
                inputPath = args[i]
            case "-out":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("output path") }
                outputPath = args[i]
            case "-algo":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("algorithm") }
                algo = args[i]
            case "-password":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("password") }
                password = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                throw SwiftSwissError.invalidOption("unknown option: \(args[i])")
            }
            i += 1
        }

        guard let inPath = inputPath else { throw SwiftSwissError.missingArgument("-in <path>") }
        let outPath = outputPath ?? "\(inPath).enc"

        let pass = password ?? readSecureInput(prompt: "Password: ")
        guard !pass.isEmpty else { throw SwiftSwissError.operationFailed("password cannot be empty") }

        let plaintext = try Data(contentsOf: URL(fileURLWithPath: inPath))
        let encrypted = try encrypt(data: plaintext, password: pass, algorithm: algo)
        try encrypted.write(to: URL(fileURLWithPath: outPath))

        print("Encrypted \(formatBytes(plaintext.count)) → \(formatBytes(encrypted.count)) (\(algo))")
    }

    public static func encrypt(data: Data, password: String, algorithm: String) throws -> Data {
        var salt = Data(count: saltSize)
        salt.withUnsafeMutableBytes { _ = SecRandomCopyBytes(kSecRandomDefault, saltSize, $0.baseAddress!) }

        let key = deriveKey(password: password, salt: salt)

        let algoByte: UInt8
        let sealedData: Data

        switch algorithm.lowercased() {
        case "aesgcm", "aes-gcm":
            algoByte = 0x01
            let sealed = try AES.GCM.seal(data, using: key)
            guard let combined = sealed.combined else {
                throw SwiftSwissError.operationFailed("AES-GCM seal failed")
            }
            sealedData = combined
        case "chacha", "chachapoly":
            algoByte = 0x02
            let sealed = try ChaChaPoly.seal(data, using: key)
            sealedData = sealed.combined
        default:
            throw SwiftSwissError.invalidOption("unknown algorithm: \(algorithm) (choices: aesgcm, chachapoly)")
        }

        return salt + Data([algoByte]) + sealedData
    }

    static func deriveKey(password: String, salt: Data) -> SymmetricKey {
        let passwordHash = SHA256.hash(data: Data(password.utf8))
        let inputKey = SymmetricKey(data: passwordHash)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("swiftswiss-v1".utf8),
            outputByteCount: 32
        )
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss encrypt -in <file> -out <file> [options]

        Encrypt a file using password-based encryption.

        Options:
          -in <path>          Input file to encrypt
          -out <path>         Output file for encrypted data (default: <input>.enc)
          -algo <algorithm>   Encryption algorithm (default: aesgcm)
                              Choices: aesgcm, chachapoly
          -password <pass>    Password (prompted securely if omitted)
          -h, --help          Show this help

        Frameworks: CryptoKit
        """)
    }
}
