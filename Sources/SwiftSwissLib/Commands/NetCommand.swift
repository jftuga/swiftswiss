import CoreLocation
import CoreWLAN
import Foundation
import Network

public enum NetCommand {
    public static func run(_ args: [String]) async throws {
        var mode = "check"
        var host: String?
        var port: UInt16 = 80
        var portEnd: UInt16?
        var timeout: Double = 5.0
        var wifiScan = false

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-host":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("host") }
                host = args[i]
            case "-port":
                i += 1; guard i < args.count, let v = UInt16(args[i]) else {
                    throw SwiftSwissError.missingArgument("port (integer)")
                }
                port = v
            case "-end":
                i += 1; guard i < args.count, let v = UInt16(args[i]) else {
                    throw SwiftSwissError.missingArgument("end port (integer)")
                }
                portEnd = v
            case "-timeout":
                i += 1; guard i < args.count, let v = Double(args[i]) else {
                    throw SwiftSwissError.missingArgument("timeout (seconds)")
                }
                timeout = v
            case "-scan":
                wifiScan = true
            case "-h", "--help":
                printHelp(); return
            default:
                if host == nil { host = args[i] }
            }
            i += 1
        }

        switch mode {
        case "check":
            guard let h = host else { throw SwiftSwissError.missingArgument("host") }
            let open = await checkPort(host: h, port: port, timeout: timeout)
            print("\(h):\(port) — \(open ? "open" : "closed/filtered")")

        case "scan":
            guard let h = host else { throw SwiftSwissError.missingArgument("host") }
            let end = portEnd ?? (port + 100)
            guard end >= port else { throw SwiftSwissError.invalidOption("-end must be >= -port") }
            print("Scanning \(h) ports \(port)-\(end)...")
            var openPorts: [UInt16] = []
            for p in port...end {
                let open = await checkPort(host: h, port: p, timeout: timeout)
                if open {
                    print("  \(p)/tcp open")
                    openPorts.append(p)
                }
            }
            print("\n\(openPorts.count) open port(s) found")

        case "status":
            await printNetworkStatus()

        case "wifi":
            if wifiScan {
                printWifiScan()
            } else {
                printWifiInfo()
            }

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: check, scan, status, wifi)")
        }
    }

    public static func checkPort(host: String, port: UInt16, timeout: Double = 5.0) async -> Bool {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(integerLiteral: port),
                using: .tcp
            )

            let lock = NSLock()
            var completed = false

            func complete(_ result: Bool) {
                lock.lock()
                defer { lock.unlock() }
                guard !completed else { return }
                completed = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    complete(true)
                case .failed(_):
                    complete(false)
                case .cancelled:
                    complete(false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                complete(false)
            }
        }
    }

    static func printNetworkStatus() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let monitor = NWPathMonitor()
            var done = false
            let lock = NSLock()

            monitor.pathUpdateHandler = { path in
                lock.lock()
                guard !done else { lock.unlock(); return }
                done = true
                lock.unlock()

                print("Network Status:")
                print("  Status:      \(path.status == .satisfied ? "connected" : "disconnected")")
                print("  Expensive:   \(path.isExpensive)")
                print("  Constrained: \(path.isConstrained)")

                var interfaces: [String] = []
                if path.usesInterfaceType(.wifi) { interfaces.append("Wi-Fi") }
                if path.usesInterfaceType(.cellular) { interfaces.append("Cellular") }
                if path.usesInterfaceType(.wiredEthernet) { interfaces.append("Ethernet") }
                if path.usesInterfaceType(.loopback) { interfaces.append("Loopback") }
                if !interfaces.isEmpty {
                    print("  Interfaces:  \(interfaces.joined(separator: ", "))")
                }

                print("  Supports DNS: \(path.supportsDNS)")
                print("  Supports IPv4: \(path.supportsIPv4)")
                print("  Supports IPv6: \(path.supportsIPv6)")

                monitor.cancel()
                continuation.resume()
            }
            monitor.start(queue: .global())
        }
    }

    // MARK: - Wi-Fi (CoreWLAN)

    public static func getCurrentSSID() -> String? {
        guard let iface = CWWiFiClient.shared().interface() else { return nil }
        return iface.ssid()
    }

    static func printWifiInfo() {
        guard let iface = CWWiFiClient.shared().interface() else {
            print("Wi-Fi: no Wi-Fi interface found")
            return
        }

        print("Wi-Fi Interface:")
        print("  Interface:    \(iface.interfaceName ?? "unknown")")

        let rssi = iface.rssiValue()
        let noise = iface.noiseMeasurement()
        let connectedButNoSSID = iface.ssid() == nil && rssi != 0

        if let ssid = iface.ssid() {
            print("  SSID:         \(ssid)")
        } else if connectedButNoSSID {
            print("  SSID:         (requires Location Services — see: System Settings > Privacy & Security > Location Services)")
        } else {
            print("  SSID:         (not connected)")
        }

        if let bssid = iface.bssid() {
            print("  BSSID:        \(bssid)")
        }
        if rssi != 0 {
            print("  RSSI:         \(rssi) dBm")
            print("  Noise:        \(noise) dBm")
            print("  SNR:          \(rssi - noise) dB")
        }

        print("  Tx Rate:      \(iface.transmitRate()) Mbps")
        print("  Tx Power:     \(iface.transmitPower()) mW")

        if let channel = iface.wlanChannel() {
            let band: String
            switch channel.channelBand {
            case .band2GHz: band = "2.4 GHz"
            case .band5GHz: band = "5 GHz"
            case .band6GHz: band = "6 GHz"
            case .bandUnknown: band = "unknown"
            @unknown default: band = "unknown"
            }
            print("  Channel:      \(channel.channelNumber) (\(band))")
        }

        let security = describeWifiSecurity(iface.security())
        print("  Security:     \(security)")

        if let cc = iface.countryCode() {
            print("  Country Code: \(cc)")
        }

        print("  Power On:     \(iface.powerOn())")

        if let hwAddr = iface.hardwareAddress() {
            print("  MAC Address:  \(hwAddr)")
        }
    }

    static func printLocationServicesHelp() {
        print("To fix this, enable Location Services for your terminal app:")
        print("  1. Open System Settings > Privacy & Security > Location Services")
        print("  2. Ensure Location Services is turned on")
        print("  3. Find your terminal app (Terminal, iTerm, etc.) and enable it")
        print()
        print("Note: macOS requires Location Services for Wi-Fi scanning to prevent")
        print("covert location tracking via nearby access points.")
    }

    static func printWifiScan() {
        guard let iface = CWWiFiClient.shared().interface() else {
            print("Wi-Fi: no Wi-Fi interface found")
            return
        }

        // Check Location Services before scanning — scanForNetworks can segfault
        // if Location Services is not authorized for the calling process.
        if !CLLocationManager.locationServicesEnabled() {
            print("Error: Location Services is disabled system-wide.")
            print()
            printLocationServicesHelp()
            return
        }

        let status = CLLocationManager().authorizationStatus
        if status == .notDetermined || status == .denied || status == .restricted {
            print("Error: Location Services not authorized for this terminal app.")
            print("  Authorization status: \(describeAuthStatus(status))")
            print()
            printLocationServicesHelp()
            return
        }

        print("Scanning for Wi-Fi networks...")
        print()

        let networks: Set<CWNetwork>
        do {
            networks = try iface.scanForNetworks(withName: nil)
        } catch let error as NSError {
            print("Error: Wi-Fi scan failed — \(error.localizedDescription)")
            print()
            printLocationServicesHelp()
            return
        }

        if networks.isEmpty {
            print("No networks found. This may indicate Location Services is not authorized.")
            print("See: System Settings > Privacy & Security > Location Services")
            return
        }

        // Sort by signal strength (strongest first)
        let sorted = networks.sorted { $0.rssiValue > $1.rssiValue }

        print(String(format: "%-32s %6s %5s %4s  %s", "SSID", "RSSI", "Chan", "Band", "Security"))
        print(String(repeating: "-", count: 72))

        for net in sorted {
            let ssid = net.ssid ?? "(hidden)"
            let rssi = net.rssiValue
            let channel = net.wlanChannel?.channelNumber ?? 0
            let band: String
            switch net.wlanChannel?.channelBand {
            case .band2GHz: band = "2.4"
            case .band5GHz: band = "5"
            case .band6GHz: band = "6"
            default: band = "?"
            }
            let security = describeNetworkSecurity(net)
            let truncatedSSID = ssid.count > 32 ? String(ssid.prefix(29)) + "..." : ssid
            print(String(format: "%-32s %3d dBm %5d %4s  %s", truncatedSSID, rssi, channel, band, security))
        }

        print()
        print("\(sorted.count) network(s) found")
    }

    static func describeAuthStatus(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "not determined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorized"
        case .authorizedWhenInUse: return "authorized (when in use)"
        @unknown default: return "unknown"
        }
    }

    static func describeWifiSecurity(_ security: CWSecurity) -> String {
        switch security {
        case .none: return "Open"
        case .WEP: return "WEP"
        case .wpaPersonal: return "WPA Personal"
        case .wpaPersonalMixed: return "WPA Personal Mixed"
        case .wpaEnterprise: return "WPA Enterprise"
        case .wpaEnterpriseMixed: return "WPA Enterprise Mixed"
        case .wpa2Personal: return "WPA2 Personal"
        case .wpa2Enterprise: return "WPA2 Enterprise"
        case .wpa3Personal: return "WPA3 Personal"
        case .wpa3Enterprise: return "WPA3 Enterprise"
        case .wpa3Transition: return "WPA3 Transition"
        case .personal: return "Personal"
        case .enterprise: return "Enterprise"
        case .dynamicWEP: return "Dynamic WEP"
        case .OWE: return "OWE"
        case .oweTransition: return "OWE Transition"
        case .unknown: return "Unknown"
        @unknown default: return "Other"
        }
    }

    static func describeNetworkSecurity(_ network: CWNetwork) -> String {
        // CWNetwork uses supportsSecurity() rather than a single security property.
        // Check from strongest to weakest and return the best match.
        let checks: [(CWSecurity, String)] = [
            (.wpa3Enterprise, "WPA3 Enterprise"),
            (.wpa3Personal, "WPA3 Personal"),
            (.wpa3Transition, "WPA3 Transition"),
            (.wpa2Enterprise, "WPA2 Enterprise"),
            (.wpa2Personal, "WPA2 Personal"),
            (.wpaEnterprise, "WPA Enterprise"),
            (.wpaPersonal, "WPA Personal"),
            (.WEP, "WEP"),
            (.dynamicWEP, "Dynamic WEP"),
        ]
        var supported: [String] = []
        for (sec, name) in checks {
            if network.supportsSecurity(sec) {
                supported.append(name)
            }
        }
        if supported.isEmpty {
            return network.supportsSecurity(.none) ? "Open" : "Unknown"
        }
        // Return the strongest (first found), or multiple if mixed
        return supported.count == 1 ? supported[0] : supported.joined(separator: ", ")
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss net -mode <mode> [options]

        Network utilities.

        Modes:
          check     Check if a TCP port is open (default)
          scan      Scan a range of TCP ports
          status    Show current network status and interfaces
          wifi      Show current Wi-Fi connection details
          wifi -scan  Scan for nearby Wi-Fi networks

        Options:
          -mode <mode>       Mode (default: check)
          -host <hostname>   Target host
          -port <n>          Port number (default: 80)
          -end <n>           End port for scan range
          -timeout <secs>    Connection timeout in seconds (default: 5.0)
          -scan              Scan for nearby networks (wifi mode only)
          -h, --help         Show this help

        Wi-Fi Notes:
          The wifi mode requires a Mac with a Wi-Fi interface.
          The -scan option requires Location Services to be enabled for your
          terminal app in System Settings > Privacy & Security > Location Services.

        Frameworks: Network (NWConnection, NWPathMonitor), CoreWLAN (CWWiFiClient)
        """)
    }
}
