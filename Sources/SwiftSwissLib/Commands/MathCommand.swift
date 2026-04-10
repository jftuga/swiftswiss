import Accelerate
import Foundation

public enum MathCommand {
    public static func run(_ args: [String]) throws {
        var mode = "stats"
        var inputPath: String?
        var fftSize: Int?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-in":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("input path") }
                inputPath = args[i]
            case "-n":
                i += 1; guard i < args.count, let v = Int(args[i]) else {
                    throw SwiftSwissError.missingArgument("FFT size (integer)")
                }
                fftSize = v
            case "-h", "--help":
                printHelp(); return
            default:
                if inputPath == nil { inputPath = args[i] }
            }
            i += 1
        }

        switch mode {
        case "stats":
            let values = try parseNumbers(from: inputPath)
            guard !values.isEmpty else {
                throw SwiftSwissError.operationFailed("no numbers found in input")
            }
            let result = computeStats(values)
            printStats(result)

        case "fft":
            let values = try parseNumbers(from: inputPath)
            guard !values.isEmpty else {
                throw SwiftSwissError.operationFailed("no numbers found in input")
            }
            let magnitudes = try computeFFT(values, requestedSize: fftSize)
            printFFT(magnitudes)

        case "linspace":
            guard let n = fftSize, n >= 2 else {
                throw SwiftSwissError.missingArgument("-n <count> (at least 2) required for linspace")
            }
            let values = try parseNumbers(from: inputPath)
            guard values.count == 2 else {
                throw SwiftSwissError.operationFailed("linspace requires exactly 2 numbers: start end")
            }
            let result = linspace(start: values[0], end: values[1], count: n)
            for v in result {
                print(formatNumber(v))
            }

        case "dot":
            let values = try parseNumbers(from: inputPath)
            guard values.count >= 2, values.count.isMultiple(of: 2) else {
                throw SwiftSwissError.operationFailed(
                    "dot product requires an even number of values (two vectors of equal length)")
            }
            let half = values.count / 2
            let a = Array(values[0..<half])
            let b = Array(values[half...])
            let result = dotProduct(a, b)
            print(formatNumber(result))

        case "norm":
            let values = try parseNumbers(from: inputPath)
            guard !values.isEmpty else {
                throw SwiftSwissError.operationFailed("no numbers found in input")
            }
            let result = l2Norm(values)
            print(formatNumber(result))

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: stats, fft, linspace, dot, norm)")
        }
    }

    // MARK: - Number parsing

    public static func parseNumbers(from path: String?) throws -> [Double] {
        let text = try readInputString(from: path)
        return text.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { Double($0) }
    }

    // MARK: - Statistics (vDSP)

    public struct Stats {
        public let count: Int
        public let sum: Double
        public let mean: Double
        public let min: Double
        public let max: Double
        public let variance: Double
        public let stddev: Double
        public let median: Double
        public let p25: Double
        public let p75: Double
    }

    public static func computeStats(_ values: [Double]) -> Stats {
        let n = vDSP_Length(values.count)

        var sum: Double = 0
        vDSP_sveD(values, 1, &sum, n)

        var mean: Double = 0
        vDSP_meanvD(values, 1, &mean, n)

        var minVal: Double = 0
        vDSP_minvD(values, 1, &minVal, n)

        var maxVal: Double = 0
        vDSP_maxvD(values, 1, &maxVal, n)

        // Variance: mean of squared differences from mean
        var negMean = -mean
        var centered = [Double](repeating: 0, count: values.count)
        vDSP_vsaddD(values, 1, &negMean, &centered, 1, n)
        var meanSqDiff: Double = 0
        vDSP_measqvD(centered, 1, &meanSqDiff, n)

        let sorted = values.sorted()
        let median = percentile(sorted, p: 0.5)
        let p25 = percentile(sorted, p: 0.25)
        let p75 = percentile(sorted, p: 0.75)

        return Stats(
            count: values.count,
            sum: sum,
            mean: mean,
            min: minVal,
            max: maxVal,
            variance: meanSqDiff,
            stddev: sqrt(meanSqDiff),
            median: median,
            p25: p25,
            p75: p75
        )
    }

    static func percentile(_ sorted: [Double], p: Double) -> Double {
        guard sorted.count > 1 else { return sorted.first ?? 0 }
        let index = p * Double(sorted.count - 1)
        let lower = Int(index)
        let upper = min(lower + 1, sorted.count - 1)
        let fraction = index - Double(lower)
        return sorted[lower] + fraction * (sorted[upper] - sorted[lower])
    }

    static func printStats(_ s: Stats) {
        print("Count:    \(s.count)")
        print("Sum:      \(formatNumber(s.sum))")
        print("Mean:     \(formatNumber(s.mean))")
        print("Median:   \(formatNumber(s.median))")
        print("Min:      \(formatNumber(s.min))")
        print("Max:      \(formatNumber(s.max))")
        print("Std Dev:  \(formatNumber(s.stddev))")
        print("Variance: \(formatNumber(s.variance))")
        print("P25:      \(formatNumber(s.p25))")
        print("P75:      \(formatNumber(s.p75))")
    }

    // MARK: - FFT (vDSP)

    public static func computeFFT(_ values: [Double], requestedSize: Int? = nil) throws -> [Double] {
        let n: Int
        if let req = requestedSize {
            guard req > 0 && (req & (req - 1)) == 0 else {
                throw SwiftSwissError.invalidOption("FFT size must be a power of 2 (got \(req))")
            }
            n = req
        } else {
            // Round up to next power of 2
            n = 1 << Int(ceil(log2(Double(max(values.count, 2)))))
        }

        let log2n = vDSP_Length(log2(Double(n)))
        guard let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2)) else {
            throw SwiftSwissError.operationFailed("failed to create FFT setup")
        }
        defer { vDSP_destroy_fftsetupD(fftSetup) }

        // Zero-pad input to size n
        var padded = [Double](repeating: 0, count: n)
        for i in 0..<min(values.count, n) {
            padded[i] = values[i]
        }

        // Pack real data into split complex (even indices → real, odd → imag)
        let halfN = n / 2
        var realp = [Double](repeating: 0, count: halfN)
        var imagp = [Double](repeating: 0, count: halfN)
        for i in 0..<halfN {
            realp[i] = padded[2 * i]
            imagp[i] = padded[2 * i + 1]
        }

        // Forward FFT
        realp.withUnsafeMutableBufferPointer { rBuf in
            imagp.withUnsafeMutableBufferPointer { iBuf in
                var sc = DSPDoubleSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
                vDSP_fft_zripD(fftSetup, &sc, 1, log2n, FFTDirection(kFFTDirection_Forward))
            }
        }

        // Compute magnitudes from the split complex result
        var magnitudes = [Double](repeating: 0, count: halfN)
        for i in 0..<halfN {
            magnitudes[i] = sqrt(realp[i] * realp[i] + imagp[i] * imagp[i]) / Double(n)
        }

        return magnitudes
    }

    static func printFFT(_ magnitudes: [Double]) {
        print("Bin  Magnitude")
        for (i, mag) in magnitudes.enumerated() {
            let binStr = String(i).padding(toLength: 4, withPad: " ", startingAt: 0)
            print("\(binStr)  \(formatNumber(mag))")
        }
    }

    // MARK: - Linear algebra (vDSP)

    public static func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        let n = min(a.count, b.count)
        var result: Double = 0
        vDSP_dotprD(a, 1, b, 1, &result, vDSP_Length(n))
        return result
    }

    public static func l2Norm(_ values: [Double]) -> Double {
        // ||v|| = sqrt(v · v)
        let dot = dotProduct(values, values)
        return sqrt(dot)
    }

    public static func linspace(start: Double, end: Double, count: Int) -> [Double] {
        var result = [Double](repeating: 0, count: count)
        var s = start
        var step = (end - start) / Double(count - 1)
        vDSP_vrampD(&s, &step, &result, 1, vDSP_Length(count))
        return result
    }

    // MARK: - Formatting

    static func formatNumber(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e15 {
            if v == 0 { return "0" }
            return String(format: "%.0f", v)
        }
        // Remove trailing zeros
        let s = String(format: "%.10g", v)
        return s
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss math -mode <mode> [options]

        Numeric and vector operations powered by Accelerate (vDSP).

        Modes:
          stats      Descriptive statistics: count, sum, mean, median, stddev, etc. (default)
          fft        Fast Fourier Transform — output frequency bin magnitudes
          dot        Dot product of two equal-length vectors (first half · second half)
          norm       L2 (Euclidean) norm of a vector
          linspace   Generate evenly spaced numbers between two endpoints

        Options:
          -mode, -m <mode>  Operation mode (default: stats)
          -in <path>     Input file (or read from stdin; numbers separated by whitespace)
          -n <size>      FFT size (must be power of 2; auto-selected if omitted)
                         For linspace: number of points to generate (required)
          -h, --help     Show this help

        Input format:
          Numbers separated by spaces or newlines. Read from file (-in) or stdin.

        Examples:
          echo "1 2 3 4 5 6 7 8 9 10" | swiftswiss math
          echo "1 2 3 4 5 6 7 8" | swiftswiss math -mode fft
          echo "1 2 3 4 5 6" | swiftswiss math -mode dot
          echo "0 100" | swiftswiss math -mode linspace -n 11
          echo "3 4" | swiftswiss math -mode norm

        Frameworks: Accelerate (vDSP)
        """)
    }
}
