import CoreML
import Foundation

public enum MLCommand {
    public static func run(_ args: [String]) throws {
        var mode = "info"
        var modelPath: String?
        var inputArgs: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-model":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("model path") }
                modelPath = args[i]
            case "-input":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("input values") }
                // Collect remaining args as input key=value pairs
                while i < args.count && !args[i].hasPrefix("-") {
                    inputArgs.append(args[i])
                    i += 1
                }
                continue
            case "-h", "--help":
                printHelp(); return
            default:
                if modelPath == nil { modelPath = args[i] }
            }
            i += 1
        }

        guard let path = modelPath else {
            throw SwiftSwissError.missingArgument("model path (.mlmodel or .mlmodelc)")
        }

        switch mode {
        case "info":
            try printModelInfo(path: path)
        case "predict":
            try predict(modelPath: path, inputArgs: inputArgs)
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: info, predict)")
        }
    }

    // MARK: - Info

    public struct ModelInfo {
        public let description: String
        public let author: String?
        public let license: String?
        public let version: String?
        public let inputs: [(name: String, type: String)]
        public let outputs: [(name: String, type: String)]
        public let metadata: [(key: String, value: String)]
    }

    public static func getModelInfo(path: String) throws -> ModelInfo {
        let url = resolveModelURL(path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SwiftSwissError.fileNotFound(path)
        }

        let compiledURL = try compileModelIfNeeded(url)
        let model = try MLModel(contentsOf: compiledURL)
        let desc = model.modelDescription

        let inputs = desc.inputDescriptionsByName.sorted(by: { $0.key < $1.key }).map {
            (name: $0.key, type: featureTypeString($0.value.type))
        }
        let outputs = desc.outputDescriptionsByName.sorted(by: { $0.key < $1.key }).map {
            (name: $0.key, type: featureTypeString($0.value.type))
        }

        var metadata: [(String, String)] = []
        if let meta = desc.metadata[.creatorDefinedKey] as? [String: String] {
            metadata = meta.sorted(by: { $0.key < $1.key }).map { ($0.key, $0.value) }
        }

        return ModelInfo(
            description: desc.metadata[.description] as? String ?? "",
            author: desc.metadata[.author] as? String,
            license: desc.metadata[.license] as? String,
            version: desc.metadata[.versionString] as? String,
            inputs: inputs,
            outputs: outputs,
            metadata: metadata
        )
    }

    static func printModelInfo(path: String) throws {
        let info = try getModelInfo(path: path)

        print("Model: \(path)")
        if !info.description.isEmpty { print("Description: \(info.description)") }
        if let author = info.author, !author.isEmpty { print("Author:      \(author)") }
        if let license = info.license, !license.isEmpty { print("License:     \(license)") }
        if let version = info.version, !version.isEmpty { print("Version:     \(version)") }

        print("\nInputs:")
        for input in info.inputs {
            print("  \(input.name): \(input.type)")
        }

        print("\nOutputs:")
        for output in info.outputs {
            print("  \(output.name): \(output.type)")
        }

        if !info.metadata.isEmpty {
            print("\nMetadata:")
            for (key, value) in info.metadata {
                print("  \(key): \(value)")
            }
        }
    }

    // MARK: - Predict

    public static func predict(modelPath: String, inputArgs: [String]) throws {
        let url = resolveModelURL(modelPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SwiftSwissError.fileNotFound(modelPath)
        }

        let compiledURL = try compileModelIfNeeded(url)
        let model = try MLModel(contentsOf: compiledURL)
        let desc = model.modelDescription

        if inputArgs.isEmpty {
            throw SwiftSwissError.missingArgument(
                "input values as key=value pairs (e.g., -input x=1.0 y=2.0)")
        }

        let provider = try buildFeatureProvider(
            from: inputArgs, schema: desc.inputDescriptionsByName)
        let result = try model.prediction(from: provider)

        for name in desc.outputDescriptionsByName.keys.sorted() {
            if let value = result.featureValue(for: name) {
                print("\(name): \(formatFeatureValue(value))")
            }
        }
    }

    // MARK: - Helpers

    static func resolveModelURL(_ path: String) -> URL {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
    }

    static func compileModelIfNeeded(_ url: URL) throws -> URL {
        if url.pathExtension == "mlmodelc" {
            return url
        }
        return try MLModel.compileModel(at: url)
    }

    static func featureTypeString(_ type: MLFeatureType) -> String {
        switch type {
        case .double:            return "Double"
        case .int64:             return "Int64"
        case .string:            return "String"
        case .image:             return "Image"
        case .multiArray:        return "MultiArray"
        case .dictionary:        return "Dictionary"
        case .sequence:          return "Sequence"
        case .invalid:           return "Invalid"
        @unknown default:        return "Unknown"
        }
    }

    static func buildFeatureProvider(
        from args: [String],
        schema: [String: MLFeatureDescription]
    ) throws -> MLDictionaryFeatureProvider {
        var dict: [String: MLFeatureValue] = [:]

        for arg in args {
            let parts = arg.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                throw SwiftSwissError.invalidOption(
                    "input must be key=value, got: \(arg)")
            }
            let key = String(parts[0])
            let valueStr = String(parts[1])

            guard let featureDesc = schema[key] else {
                let valid = schema.keys.sorted().joined(separator: ", ")
                throw SwiftSwissError.invalidOption(
                    "unknown input '\(key)'. Valid inputs: \(valid)")
            }

            switch featureDesc.type {
            case .double:
                guard let val = Double(valueStr) else {
                    throw SwiftSwissError.invalidOption(
                        "expected Double for '\(key)', got: \(valueStr)")
                }
                dict[key] = MLFeatureValue(double: val)
            case .int64:
                guard let val = Int64(valueStr) else {
                    throw SwiftSwissError.invalidOption(
                        "expected Int64 for '\(key)', got: \(valueStr)")
                }
                dict[key] = MLFeatureValue(int64: val)
            case .string:
                dict[key] = MLFeatureValue(string: valueStr)
            default:
                throw SwiftSwissError.operationFailed(
                    "input type \(featureTypeString(featureDesc.type)) for '\(key)' is not supported via CLI key=value pairs")
            }
        }

        return try MLDictionaryFeatureProvider(dictionary: dict)
    }

    static func formatFeatureValue(_ value: MLFeatureValue) -> String {
        switch value.type {
        case .double:       return String(value.doubleValue)
        case .int64:        return String(value.int64Value)
        case .string:       return value.stringValue
        case .dictionary:
            if let dict = value.dictionaryValue as? [String: NSNumber] {
                let sorted = dict.sorted { $0.value.doubleValue > $1.value.doubleValue }
                let items = sorted.prefix(10).map { "\($0.key): \($0.value)" }
                return items.joined(separator: ", ")
            }
            return "\(value.dictionaryValue)"
        case .multiArray:
            if let arr = value.multiArrayValue {
                let shape = arr.shape.map { $0.intValue }
                return "MultiArray shape=\(shape)"
            }
            return "MultiArray"
        case .image, .sequence, .invalid:
            return "\(value)"
        @unknown default:
            return "\(value)"
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss ml [options] <model.mlmodel>

        Inspect CoreML models and run predictions.

        Modes:
          info        Show model metadata, inputs, and outputs (default)
          predict     Run a prediction with key=value inputs

        Options:
          -mode, -m <mode>   Mode (default: info)
          -model <path>      Path to .mlmodel or .mlmodelc
          -input <k=v ...>   Input values for prediction (key=value pairs)
          -h, --help         Show this help

        Examples:
          swiftswiss ml model.mlmodel
          swiftswiss ml -mode info -model classifier.mlmodel
          swiftswiss ml -mode predict -model regressor.mlmodel -input x=1.0 y=2.0

        Frameworks: CoreML
        """)
    }
}
