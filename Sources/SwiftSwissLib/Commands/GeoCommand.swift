import CoreLocation
import Foundation

public enum GeoCommand {
    public static func run(_ args: [String]) async throws {
        var mode = "forward"
        var address: String?
        var lat: Double?
        var lon: Double?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-lat":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("latitude (number)")
                }
                lat = v
            case "-lon":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("longitude (number)")
                }
                lon = v
            case "-h", "--help":
                printHelp(); return
            default:
                if address == nil {
                    address = args[i]
                } else {
                    address = address! + " " + args[i]
                }
            }
            i += 1
        }

        let geocoder = CLGeocoder()

        switch mode {
        case "forward":
            guard let addr = address else { throw SwiftSwissError.missingArgument("address") }
            let placemarks = try await geocoder.geocodeAddressString(addr)
            if placemarks.isEmpty {
                print("No results found for: \(addr)")
                return
            }
            for (idx, pm) in placemarks.enumerated() {
                if placemarks.count > 1 { print("Result \(idx + 1):") }
                printPlacemark(pm)
            }

        case "reverse":
            guard let latitude = lat, let longitude = lon else {
                throw SwiftSwissError.missingArgument("-lat and -lon required for reverse geocoding")
            }
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if placemarks.isEmpty {
                print("No results found for: \(latitude), \(longitude)")
                return
            }
            for pm in placemarks {
                printPlacemark(pm)
            }

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: forward, reverse)")
        }
    }

    static func printPlacemark(_ pm: CLPlacemark) {
        if let coord = pm.location?.coordinate {
            print("  Latitude:     \(coord.latitude)")
            print("  Longitude:    \(coord.longitude)")
        }
        if let name = pm.name { print("  Name:         \(name)") }
        if let street = pm.thoroughfare { print("  Street:       \(street)") }
        if let city = pm.locality { print("  City:         \(city)") }
        if let state = pm.administrativeArea { print("  State:        \(state)") }
        if let zip = pm.postalCode { print("  Postal Code:  \(zip)") }
        if let country = pm.country { print("  Country:      \(country)") }
        if let isoCountry = pm.isoCountryCode { print("  ISO Code:     \(isoCountry)") }
        if let tz = pm.timeZone { print("  Timezone:     \(tz.identifier)") }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss geo -mode <mode> [options]

        Forward and reverse geocoding.

        Modes:
          forward    Convert an address to coordinates (default)
          reverse    Convert coordinates to an address

        Options:
          -mode, -m <mode>  Mode (default: forward)
          -lat <number>   Latitude for reverse geocoding
          -lon <number>   Longitude for reverse geocoding
          -h, --help      Show this help

        Examples:
          swiftswiss geo "1 Apple Park Way, Cupertino, CA"
          swiftswiss geo -mode reverse -lat 37.3349 -lon -122.0090

        Frameworks: CoreLocation (CLGeocoder)
        """)
    }
}
