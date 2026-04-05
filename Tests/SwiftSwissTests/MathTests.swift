@testable import SwiftSwissLib
import XCTest

final class MathTests: XCTestCase {

    // MARK: - Number parsing

    func testParseNumbersFromWhitespace() throws {
        let dir = NSTemporaryDirectory()
        let path = writeTestFile(dir: dir, name: "math_input.txt", content: "1 2 3\n4 5\n6")
        defer { try? FileManager.default.removeItem(atPath: path) }

        let nums = try MathCommand.parseNumbers(from: path)
        XCTAssertEqual(nums, [1, 2, 3, 4, 5, 6])
    }

    func testParseNumbersWithDecimalAndNegative() throws {
        let dir = NSTemporaryDirectory()
        let path = writeTestFile(dir: dir, name: "math_neg.txt", content: "-3.5 0 2.7 -1")
        defer { try? FileManager.default.removeItem(atPath: path) }

        let nums = try MathCommand.parseNumbers(from: path)
        XCTAssertEqual(nums, [-3.5, 0, 2.7, -1])
    }

    func testParseNumbersIgnoresNonNumeric() throws {
        let dir = NSTemporaryDirectory()
        let path = writeTestFile(dir: dir, name: "math_mixed.txt", content: "1 hello 3 world 5")
        defer { try? FileManager.default.removeItem(atPath: path) }

        let nums = try MathCommand.parseNumbers(from: path)
        XCTAssertEqual(nums, [1, 3, 5])
    }

    // MARK: - Statistics

    func testStatsBasic() {
        let s = MathCommand.computeStats([1, 2, 3, 4, 5])
        XCTAssertEqual(s.count, 5)
        XCTAssertEqual(s.sum, 15.0, accuracy: 1e-10)
        XCTAssertEqual(s.mean, 3.0, accuracy: 1e-10)
        XCTAssertEqual(s.min, 1.0, accuracy: 1e-10)
        XCTAssertEqual(s.max, 5.0, accuracy: 1e-10)
        XCTAssertEqual(s.median, 3.0, accuracy: 1e-10)
    }

    func testStatsStdDev() {
        // Known: stddev of [2, 4, 4, 4, 5, 5, 7, 9] population = 2.0
        let s = MathCommand.computeStats([2, 4, 4, 4, 5, 5, 7, 9])
        XCTAssertEqual(s.mean, 5.0, accuracy: 1e-10)
        XCTAssertEqual(s.variance, 4.0, accuracy: 1e-10)
        XCTAssertEqual(s.stddev, 2.0, accuracy: 1e-10)
    }

    func testStatsPercentiles() {
        let s = MathCommand.computeStats([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        XCTAssertEqual(s.p25, 3.25, accuracy: 1e-10)
        XCTAssertEqual(s.median, 5.5, accuracy: 1e-10)
        XCTAssertEqual(s.p75, 7.75, accuracy: 1e-10)
    }

    func testStatsSingleValue() {
        let s = MathCommand.computeStats([42])
        XCTAssertEqual(s.count, 1)
        XCTAssertEqual(s.sum, 42.0, accuracy: 1e-10)
        XCTAssertEqual(s.mean, 42.0, accuracy: 1e-10)
        XCTAssertEqual(s.min, 42.0, accuracy: 1e-10)
        XCTAssertEqual(s.max, 42.0, accuracy: 1e-10)
        XCTAssertEqual(s.stddev, 0.0, accuracy: 1e-10)
    }

    func testStatsNegativeValues() {
        let s = MathCommand.computeStats([-5, -3, -1, 1, 3, 5])
        XCTAssertEqual(s.mean, 0.0, accuracy: 1e-10)
        XCTAssertEqual(s.min, -5.0, accuracy: 1e-10)
        XCTAssertEqual(s.max, 5.0, accuracy: 1e-10)
    }

    func testStatsOutput() {
        let output = captureStdout {
            try! MathCommand.run(["-mode", "stats", "-in",
                writeTestFile(dir: NSTemporaryDirectory(), name: "stats_out.txt", content: "1 2 3 4 5")])
        }
        XCTAssertTrue(output.contains("Count:    5"))
        XCTAssertTrue(output.contains("Mean:     3"))
        XCTAssertTrue(output.contains("Sum:      15"))
    }

    // MARK: - FFT

    func testFFTPowerOfTwo() throws {
        // 8 samples of a DC signal (all 1s) — FFT should have energy only in bin 0
        let values = [Double](repeating: 1.0, count: 8)
        let mags = try MathCommand.computeFFT(values)
        // Bin 0 (DC) should have the largest magnitude
        XCTAssertTrue(mags[0] > mags[1])
        // Other bins should be near zero
        for i in 1..<mags.count {
            XCTAssertEqual(mags[i], 0.0, accuracy: 1e-10)
        }
    }

    func testFFTSineWave() throws {
        // Generate a sine wave at bin 2 of an 8-point FFT
        let n = 8
        let freq = 2
        let values = (0..<n).map { sin(2.0 * .pi * Double(freq) * Double($0) / Double(n)) }
        let mags = try MathCommand.computeFFT(values, requestedSize: n)
        // Bin 2 should have the peak
        let peakBin = mags.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(peakBin, freq)
    }

    func testFFTNonPowerOfTwoAutoRoundsUp() throws {
        // 5 values should auto-pad to 8
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let mags = try MathCommand.computeFFT(values)
        XCTAssertEqual(mags.count, 4) // 8/2 = 4 bins
    }

    func testFFTInvalidSizeThrows() {
        XCTAssertThrowsError(try MathCommand.computeFFT([1, 2, 3], requestedSize: 6)) { error in
            XCTAssertTrue("\(error)".contains("power of 2"))
        }
    }

    // MARK: - Dot product

    func testDotProduct() {
        let result = MathCommand.dotProduct([1, 2, 3], [4, 5, 6])
        XCTAssertEqual(result, 32.0, accuracy: 1e-10) // 1*4 + 2*5 + 3*6 = 32
    }

    func testDotProductOrthogonal() {
        let result = MathCommand.dotProduct([1, 0], [0, 1])
        XCTAssertEqual(result, 0.0, accuracy: 1e-10)
    }

    // MARK: - L2 Norm

    func testL2Norm() {
        let result = MathCommand.l2Norm([3, 4])
        XCTAssertEqual(result, 5.0, accuracy: 1e-10) // 3-4-5 triangle
    }

    func testL2NormUnitVector() {
        let result = MathCommand.l2Norm([1, 0, 0])
        XCTAssertEqual(result, 1.0, accuracy: 1e-10)
    }

    // MARK: - Linspace

    func testLinspace() {
        let result = MathCommand.linspace(start: 0, end: 10, count: 6)
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result[0], 0.0, accuracy: 1e-10)
        XCTAssertEqual(result[1], 2.0, accuracy: 1e-10)
        XCTAssertEqual(result[5], 10.0, accuracy: 1e-10)
    }

    func testLinspaceNegativeRange() {
        let result = MathCommand.linspace(start: -1, end: 1, count: 3)
        XCTAssertEqual(result, [-1.0, 0.0, 1.0])
    }

    // MARK: - CLI output integration

    func testDotModeOutput() {
        let output = captureStdout {
            try! MathCommand.run(["-mode", "dot", "-in",
                writeTestFile(dir: NSTemporaryDirectory(), name: "dot.txt", content: "1 2 3 4 5 6")])
        }
        XCTAssertTrue(output.trimmingCharacters(in: .whitespacesAndNewlines) == "32")
    }

    func testNormModeOutput() {
        let output = captureStdout {
            try! MathCommand.run(["-mode", "norm", "-in",
                writeTestFile(dir: NSTemporaryDirectory(), name: "norm.txt", content: "3 4")])
        }
        XCTAssertTrue(output.trimmingCharacters(in: .whitespacesAndNewlines) == "5")
    }

    func testLinspaceModeOutput() {
        let output = captureStdout {
            try! MathCommand.run(["-mode", "linspace", "-n", "3", "-in",
                writeTestFile(dir: NSTemporaryDirectory(), name: "linspace.txt", content: "0 10")])
        }
        let lines = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "0")
        XCTAssertEqual(lines[1], "5")
        XCTAssertEqual(lines[2], "10")
    }

    func testUnknownModeThrows() {
        XCTAssertThrowsError(try MathCommand.run(["-mode", "bogus"])) { error in
            XCTAssertTrue("\(error)".contains("unknown mode"))
        }
    }

    func testEmptyInputThrows() {
        XCTAssertThrowsError(try MathCommand.run(["-in",
            writeTestFile(dir: NSTemporaryDirectory(), name: "empty_math.txt", content: "")])) { error in
            XCTAssertTrue("\(error)".contains("no numbers"))
        }
    }
}
