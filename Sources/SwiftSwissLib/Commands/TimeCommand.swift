import Foundation

public enum TimeCommand {
    public static func run(_ args: [String]) throws {
        var mode = "now"
        var input: String?
        var format: String?
        var timezone: String?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-format":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("format") }
                format = args[i]
            case "-tz":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("timezone") }
                timezone = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                input = args[i]
            }
            i += 1
        }

        let tz: TimeZone
        if let tzName = timezone {
            guard let resolved = TimeZone(identifier: tzName) ?? TimeZone(abbreviation: tzName) else {
                throw SwiftSwissError.invalidOption("unknown timezone: \(tzName)")
            }
            tz = resolved
        } else {
            tz = .current
        }

        switch mode {
        case "now":
            printNow(timezone: tz, format: format)
        case "toepoch":
            guard let input = input else { throw SwiftSwissError.missingArgument("date string") }
            try printToEpoch(input, format: format, timezone: tz)
        case "fromepoch":
            guard let input = input else { throw SwiftSwissError.missingArgument("epoch value") }
            try printFromEpoch(input, format: format, timezone: tz)
        case "zones":
            printTimezones()
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: now, toepoch, fromepoch, zones)")
        }
    }

    public static func formatDate(_ date: Date, format: String?, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        if let fmt = format {
            formatter.dateFormat = fmt
        } else {
            formatter.dateStyle = .full
            formatter.timeStyle = .full
        }
        return formatter.string(from: date)
    }

    static func printNow(timezone: TimeZone, format: String?) {
        let now = Date()
        let iso = ISO8601DateFormatter()
        iso.timeZone = timezone

        print("ISO 8601:   \(iso.string(from: now))")
        print("Unix:       \(Int(now.timeIntervalSince1970))")
        print("Unix (ms):  \(Int(now.timeIntervalSince1970 * 1000))")
        print("Formatted:  \(formatDate(now, format: format, timezone: timezone))")
        print("Timezone:   \(timezone.identifier) (\(timezone.abbreviation() ?? "?"))")

        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timezone, from: now)
        print("Components: year=\(components.year ?? 0) month=\(components.month ?? 0) day=\(components.day ?? 0) " +
              "hour=\(components.hour ?? 0) minute=\(components.minute ?? 0) second=\(components.second ?? 0)")
        if #available(macOS 15, *) {
            print("Day of year: \(components.dayOfYear ?? 0)")
        }
        print("Week of year: \(components.weekOfYear ?? 0)")
    }

    static func printToEpoch(_ input: String, format: String?, timezone: TimeZone) throws {
        let date = try parseDate(input, format: format, timezone: timezone)
        print(Int(date.timeIntervalSince1970))
    }

    static func printFromEpoch(_ input: String, format: String?, timezone: TimeZone) throws {
        let epoch: Double
        if let v = Double(input) {
            // Auto-detect seconds vs milliseconds
            epoch = v > 1e12 ? v / 1000.0 : v
        } else {
            throw SwiftSwissError.invalidOption("invalid epoch value: \(input)")
        }

        let date = Date(timeIntervalSince1970: epoch)
        let iso = ISO8601DateFormatter()
        iso.timeZone = timezone

        print("ISO 8601:  \(iso.string(from: date))")
        print("Formatted: \(formatDate(date, format: format, timezone: timezone))")
        print("Unix:      \(Int(date.timeIntervalSince1970))")
    }

    public static func parseDate(_ input: String, format: String? = nil, timezone: TimeZone = .current) throws -> Date {
        if let fmt = format {
            let formatter = DateFormatter()
            formatter.dateFormat = fmt
            formatter.timeZone = timezone
            guard let date = formatter.date(from: input) else {
                throw SwiftSwissError.operationFailed("cannot parse '\(input)' with format '\(fmt)'")
            }
            return date
        }

        // Try ISO 8601
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: input) { return date }

        // Try common formats
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy",
            "dd-MMM-yyyy",
        ]
        for fmt in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = fmt
            formatter.timeZone = timezone
            if let date = formatter.date(from: input) { return date }
        }

        throw SwiftSwissError.operationFailed("cannot parse date: '\(input)' (try -format)")
    }

    static func printTimezones() {
        let zones = TimeZone.knownTimeZoneIdentifiers.sorted()
        let now = Date()
        for id in zones {
            guard let tz = TimeZone(identifier: id) else { continue }
            let offset = tz.secondsFromGMT(for: now)
            let hours = offset / 3600
            let minutes = abs(offset % 3600) / 60
            let sign = offset >= 0 ? "+" : "-"
            let abbr = tz.abbreviation(for: now) ?? ""
            let abbrPadded = abbr.padding(toLength: 6, withPad: " ", startingAt: 0)
            print("UTC\(sign)\(String(format: "%02d", abs(hours))):\(String(format: "%02d", minutes))  \(abbrPadded)  \(id)")
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss time [options] [value]

        Convert and display timestamps.

        Modes:
          now          Show current time in various formats (default)
          toepoch      Convert a date string to Unix epoch seconds
          fromepoch    Convert a Unix epoch to human-readable date
          zones        List all known timezones with UTC offsets

        Options:
          -mode, -m <mode> Mode (default: now)
          -format <fmt>    Date format string (e.g., "yyyy-MM-dd HH:mm:ss")
          -tz <timezone>   Timezone identifier (e.g., "America/New_York", "UTC")
          -h, --help       Show this help

        Frameworks: Foundation (Date, Calendar, DateFormatter, TimeZone)
        """)
    }
}
