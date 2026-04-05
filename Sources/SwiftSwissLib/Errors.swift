import Foundation

public enum SwiftSwissError: Error, CustomStringConvertible {
    case missingArgument(String)
    case invalidOption(String)
    case fileNotFound(String)
    case operationFailed(String)

    public var description: String {
        switch self {
        case .missingArgument(let msg): return "missing argument: \(msg)"
        case .invalidOption(let msg): return "invalid option: \(msg)"
        case .fileNotFound(let path): return "file not found: \(path)"
        case .operationFailed(let msg): return msg
        }
    }
}
