import Foundation
import os

public let appLogger = Logger(subsystem: "com.swiftswiss", category: "general")

/// Read input data from a file path or stdin if path is nil or "-".
public func readInput(from path: String?) throws -> Data {
    if let path = path, path != "-" {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw SwiftSwissError.fileNotFound(path)
        }
        return try Data(contentsOf: url)
    }
    return FileHandle.standardInput.readDataToEndOfFile()
}

/// Read input as a UTF-8 string from a file path or stdin.
public func readInputString(from path: String?) throws -> String {
    let data = try readInput(from: path)
    guard let string = String(data: data, encoding: .utf8) else {
        throw SwiftSwissError.operationFailed("input is not valid UTF-8")
    }
    return string
}

/// Write data to a file path or stdout if path is nil.
public func writeOutput(_ data: Data, to path: String?) throws {
    if let path = path {
        try data.write(to: URL(fileURLWithPath: path))
    } else {
        FileHandle.standardOutput.write(data)
    }
}

/// Format a byte count as a human-readable string.
public func formatBytes(_ bytes: Int) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var value = Double(bytes)
    for unit in units {
        if value < 1024 {
            return String(format: "%.1f %@", value, unit)
        }
        value /= 1024
    }
    return String(format: "%.1f PB", value)
}

/// Format seconds as a human-readable duration.
public func formatDuration(_ seconds: Double) -> String {
    let totalSeconds = Int(seconds)
    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60

    var parts: [String] = []
    if days > 0 { parts.append("\(days)d") }
    if hours > 0 { parts.append("\(hours)h") }
    if minutes > 0 { parts.append("\(minutes)m") }
    parts.append("\(secs)s")
    return parts.joined(separator: " ")
}

/// Read a password from the terminal without echoing.
public func readSecureInput(prompt: String) -> String {
    print(prompt, terminator: "")
    fflush(stdout)

    var oldTermios = termios()
    tcgetattr(STDIN_FILENO, &oldTermios)

    var newTermios = oldTermios
    newTermios.c_lflag &= ~tcflag_t(ECHO)
    tcsetattr(STDIN_FILENO, TCSANOW, &newTermios)

    let input = readLine() ?? ""

    tcsetattr(STDIN_FILENO, TCSANOW, &oldTermios)
    print() // newline after hidden input
    return input
}

/// Print to stderr.
public func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}
