import CryptoKit
import Foundation

public enum DecryptCommand {
    public static func run(_ args: [String]) throws {
        var inputPath: String?
        var outputPath: String?
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
        let outPath: String
        if let outputPath {
            outPath = outputPath
        } else if inPath.hasSuffix(".enc") {
            outPath = String(inPath.dropLast(4))
        } else {
            throw SwiftSwissError.missingArgument("-out <path> (required when input file does not end in .enc)")
        }

        let pass = password ?? readSecureInput(prompt: "Password: ")
        guard !pass.isEmpty else { throw SwiftSwissError.operationFailed("password cannot be empty") }

        let encrypted = try Data(contentsOf: URL(fileURLWithPath: inPath))
        let decrypted = try decrypt(data: encrypted, password: pass)
        try decrypted.write(to: URL(fileURLWithPath: outPath))

        print("Decrypted \(formatBytes(encrypted.count)) → \(formatBytes(decrypted.count))")
    }

    public static func decrypt(data: Data, password: String) throws -> Data {
        let saltSize = EncryptCommand.saltSize
        guard data.count > saltSize + 1 else {
            throw SwiftSwissError.operationFailed("encrypted data is too short")
        }

        let salt = data[0..<saltSize]
        let algoByte = data[saltSize]
        let sealedData = data[(saltSize + 1)...]

        let key = EncryptCommand.deriveKey(password: password, salt: salt)

        switch algoByte {
        case 0x01:
            let sealedBox = try AES.GCM.SealedBox(combined: sealedData)
            return try AES.GCM.open(sealedBox, using: key)
        case 0x02:
            let sealedBox = try ChaChaPoly.SealedBox(combined: sealedData)
            return try ChaChaPoly.open(sealedBox, using: key)
        default:
            throw SwiftSwissError.operationFailed("unknown encryption algorithm byte: 0x\(String(format: "%02x", algoByte))")
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss decrypt -in <file> -out <file> [options]

        Decrypt a file encrypted with the encrypt command.

        Options:
          -in <path>        Input encrypted file
          -out <path>       Output file for decrypted data (default: strip .enc suffix)
          -password <pass>  Password (prompted securely if omitted)
          -h, --help        Show this help

        Frameworks: CryptoKit
        """)
    }
}
