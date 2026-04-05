import Foundation
import XCTest

/// Capture stdout output from a closure.
func captureStdout(_ block: () throws -> Void) rethrows -> String {
    let pipe = Pipe()
    let originalStdout = dup(STDOUT_FILENO)

    fflush(stdout)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

    try block()

    fflush(stdout)
    dup2(originalStdout, STDOUT_FILENO)
    close(originalStdout)
    pipe.fileHandleForWriting.closeFile()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

/// Capture stdout from an async closure.
func captureStdoutAsync(_ block: () async throws -> Void) async rethrows -> String {
    let pipe = Pipe()
    let originalStdout = dup(STDOUT_FILENO)

    fflush(stdout)
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

    try await block()

    fflush(stdout)
    dup2(originalStdout, STDOUT_FILENO)
    close(originalStdout)
    pipe.fileHandleForWriting.closeFile()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

/// Write test content to a temp file.
func writeTestFile(dir: String, name: String, content: String) -> String {
    let path = (dir as NSString).appendingPathComponent(name)
    try! content.write(toFile: path, atomically: true, encoding: .utf8)
    return path
}

/// Write test content as Data to a temp file.
func writeTestData(dir: String, name: String, data: Data) -> String {
    let path = (dir as NSString).appendingPathComponent(name)
    try! data.write(to: URL(fileURLWithPath: path))
    return path
}
