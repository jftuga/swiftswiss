import Foundation

public enum SwiftSwiss {
    public static let version = "0.4.0"
    public static let name = "swiftswiss"
    public static let url = "https://github.com/jftuga/swiftswiss"


    public static func run(_ args: [String]) async {
        guard let command = args.first else {
            printUsage()
            return
        }

        let commandArgs = Array(args.dropFirst())

        do {
            switch command {
            // Crypto
            case "hash":       try HashCommand.run(commandArgs)
            case "encrypt":    try EncryptCommand.run(commandArgs)
            case "decrypt":    try DecryptCommand.run(commandArgs)
            case "generate":   try GenerateCommand.run(commandArgs)

            // Math & Science
            case "math":       try MathCommand.run(commandArgs)

            // Text & Data
            case "nlp":        try NLPCommand.run(commandArgs)
            case "json":       try JSONCommand.run(commandArgs)
            case "time":       try TimeCommand.run(commandArgs)
            case "transform":  try TransformCommand.run(commandArgs)

            // Media & Image
            case "ocr":        try OCRCommand.run(commandArgs)
            case "image":      try ImageCommand.run(commandArgs)
            case "media":      try await MediaCommand.run(commandArgs)
            case "speak":      try SpeakCommand.run(commandArgs)
            case "pdf":
                if (commandArgs.contains("-mode") || commandArgs.contains("-m")) && commandArgs.contains("merge") {
                    try PDFCommand.runMerge(args: commandArgs)
                } else {
                    try PDFCommand.run(commandArgs)
                }

            // System & Network
            case "net":        try await NetCommand.run(commandArgs)
            case "geo":        try await GeoCommand.run(commandArgs)
            case "info":       try InfoCommand.run(commandArgs)
            case "filetype":   try FileTypeCommand.run(commandArgs)
            case "keychain":   try KeychainCommand.run(commandArgs)
            case "compress":   try CompressCommand.run(commandArgs)
            case "spotlight":  try SpotlightCommand.run(commandArgs)
            case "ml":         try MLCommand.run(commandArgs)
            case "disk":       try DiskCommand.run(commandArgs)

            case "version":
                print("\(name) v\(version)")
                print("\(url)")
                print("Swift \(swiftVersion())")
                print("Frameworks: 23 Apple frameworks, 0 third-party packages")

            case "-h", "--help", "help":
                printUsage()

            default:
                printError("unknown command: \(command)")
                print()
                printUsage()
                exit(1)
            }
        } catch {
            printError("\(error)")
            exit(1)
        }
    }

    static func swiftVersion() -> String {
        #if swift(>=6.0)
        return "6.x"
        #elseif swift(>=5.9)
        return "5.9+"
        #else
        return "5.x"
        #endif
    }

    public static func printUsage() {
        let usage = """
        \(name) v\(version) — a Swiss army knife CLI using 23 Apple frameworks

        Usage: \(name) <command> [options]

        Math & Science:
          math         Numeric operations: statistics, FFT, dot product, L2 norm, linspace

        Machine Learning:
          ml           Inspect CoreML models and run predictions

        Crypto:
          hash         Compute hashes of files or stdin (SHA-256/384/512, HMAC)
          encrypt      Encrypt a file with AES-GCM or ChaChaPoly
          decrypt      Decrypt a file encrypted with the encrypt command
          generate     Generate passwords, UUIDs, random bytes, or symmetric keys

        Text & Data:
          nlp          Natural language processing (detect, sentiment, entities, POS, tokenize, lemma)
          json         Process JSON (pretty, compact, validate, query)
          time         Convert timestamps (now, toepoch, fromepoch, zones)
          transform    Transform text (upper, lower, reverse, count, replace, base64)

        Media & Image:
          ocr          Extract text from images via OCR
          image        Resize, convert, filter, or inspect image metadata
          media        Inspect audio/video file metadata and tracks
          speak        Text-to-speech synthesis
          pdf          Extract text, search, split, merge, and inspect PDFs

        System & Network:
          net          Network utilities (check ports, scan, status, wifi, tls, dns)
          geo          Forward/reverse geocoding
          info         Display system, power, and network information
          filetype     Identify file types and MIME types
          keychain     Store, retrieve, and manage Keychain secrets
          compress     Compress/decompress data (LZFSE, LZ4, ZLIB, LZMA)
          spotlight    Search Spotlight index for files
          disk         List mounted volumes and watch disk events

        Other:
          version      Show version information
          help         Show this help message

        Run '\(name) <command> -h' for help on a specific command.
        """
        print(usage)
    }
}
