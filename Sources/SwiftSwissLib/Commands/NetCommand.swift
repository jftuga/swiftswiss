import CoreLocation
import CoreWLAN
import Foundation
import CResolv
import Network
import Security

public enum NetCommand {
    public static func run(_ args: [String]) async throws {
        var mode = "check"
        var host: String?
        var port: UInt16 = 80
        var portSpecified = false
        var portEnd: UInt16?
        var timeout: Double = 5.0
        var wifiScan = false

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
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
                portSpecified = true
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

        case "tls":
            guard let h = host else { throw SwiftSwissError.missingArgument("host") }
            try await inspectTLS(host: h, port: portSpecified ? port : 443)

        case "dns":
            guard let h = host else { throw SwiftSwissError.missingArgument("host") }
            try inspectDNS(host: h)

        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: check, scan, status, wifi, tls, dns)")
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
            print(
                "  SSID:         (requires Location Services — see: System Settings > Privacy & Security > Location Services)"
            )
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

        print(
            String(
                format: "%-32s %6s %5s %4s  %s", "SSID", "RSSI", "Chan", "Band", "Security"))
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
            print(
                String(
                    format: "%-32s %3d dBm %5d %4s  %s", truncatedSSID, rssi, channel, band,
                    security))
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

    // MARK: - TLS Inspection

    public static func inspectTLS(host: String, port: UInt16) async throws {
        var capturedTrust: SecTrust?
        var capturedVersion: tls_protocol_version_t?
        var capturedCipherSuite: tls_ciphersuite_t?
        var capturedALPN: String?

        let tlsOptions = NWProtocolTLS.Options()

        // Advertise common ALPN protocols so servers can negotiate
        sec_protocol_options_add_tls_application_protocol(
            tlsOptions.securityProtocolOptions, "h2")
        sec_protocol_options_add_tls_application_protocol(
            tlsOptions.securityProtocolOptions, "http/1.1")

        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { metadata, trust, completion in
                capturedVersion = sec_protocol_metadata_get_negotiated_tls_protocol_version(
                    metadata)
                capturedCipherSuite = sec_protocol_metadata_get_negotiated_tls_ciphersuite(
                    metadata)
                if let proto = sec_protocol_metadata_get_negotiated_protocol(metadata) {
                    capturedALPN = String(cString: proto)
                }
                capturedTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                completion(true)
            },
            DispatchQueue.global()
        )

        let params = NWParameters(tls: tlsOptions)
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: port),
            using: params
        )

        try await withCheckedThrowingContinuation {
            (cont: CheckedContinuation<Void, Error>) in
            let lock = NSLock()
            var completed = false

            connection.stateUpdateHandler = { state in
                lock.lock()
                guard !completed else { lock.unlock(); return }
                switch state {
                case .ready:
                    completed = true
                    lock.unlock()
                    cont.resume()
                case .failed(let error):
                    completed = true
                    lock.unlock()
                    cont.resume(throwing: error)
                case .cancelled:
                    completed = true
                    lock.unlock()
                    cont.resume(
                        throwing: SwiftSwissError.operationFailed("TLS connection cancelled"))
                default:
                    lock.unlock()
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) {
                lock.lock()
                guard !completed else { lock.unlock(); return }
                completed = true
                lock.unlock()
                connection.cancel()
                cont.resume(
                    throwing: SwiftSwissError.operationFailed(
                        "TLS connection to \(host):\(port) timed out"))
            }
        }

        defer { connection.cancel() }

        let versionStr = capturedVersion.map { tlsVersionString($0) } ?? "unknown"
        print("TLS \(versionStr) connected to \(host):\(port)\n")
        print("Cipher Suite: \(capturedCipherSuite.map { cipherSuiteName($0) } ?? "unknown")")
        print("ALPN Protocol: \(capturedALPN ?? "")")

        guard let trust = capturedTrust else {
            print("\nNo certificate chain available")
            return
        }

        var trustError: CFError?
        let trustResult = SecTrustEvaluateWithError(trust, &trustError)

        guard let certChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate] else {
            print("\nNo certificates found")
            return
        }

        for (i, cert) in certChain.enumerated() {
            print("\nCertificate #\(i + 1):")
            printCertDetails(
                cert, isLeaf: i == 0,
                verified: i == 0 ? trustResult : nil,
                trustError: i == 0 ? trustError : nil)
        }
    }

    static func tlsVersionString(_ version: tls_protocol_version_t) -> String {
        switch version {
        case .TLSv10: return "1.0"
        case .TLSv11: return "1.1"
        case .TLSv12: return "1.2"
        case .TLSv13: return "1.3"
        case .DTLSv10: return "DTLS 1.0"
        case .DTLSv12: return "DTLS 1.2"
        @unknown default: return "unknown"
        }
    }

    static func cipherSuiteName(_ suite: tls_ciphersuite_t) -> String {
        switch suite {
        case .AES_128_GCM_SHA256: return "TLS_AES_128_GCM_SHA256"
        case .AES_256_GCM_SHA384: return "TLS_AES_256_GCM_SHA384"
        case .CHACHA20_POLY1305_SHA256: return "TLS_CHACHA20_POLY1305_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:
            return "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:
            return "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_RSA_WITH_AES_256_GCM_SHA384:
            return "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_RSA_WITH_AES_128_GCM_SHA256:
            return "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:
            return "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
        case .ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:
            return "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
        case .RSA_WITH_AES_128_GCM_SHA256: return "TLS_RSA_WITH_AES_128_GCM_SHA256"
        case .RSA_WITH_AES_256_GCM_SHA384: return "TLS_RSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:
            return "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA384:
            return "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA256:
            return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA384:
            return "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384"
        case .RSA_WITH_3DES_EDE_CBC_SHA: return "TLS_RSA_WITH_3DES_EDE_CBC_SHA"
        case .RSA_WITH_AES_128_CBC_SHA: return "TLS_RSA_WITH_AES_128_CBC_SHA"
        case .RSA_WITH_AES_256_CBC_SHA: return "TLS_RSA_WITH_AES_256_CBC_SHA"
        case .RSA_WITH_AES_128_CBC_SHA256: return "TLS_RSA_WITH_AES_128_CBC_SHA256"
        case .RSA_WITH_AES_256_CBC_SHA256: return "TLS_RSA_WITH_AES_256_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
            return "TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA:
            return "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA:
            return "TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA"
        case .ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
            return "TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA: return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA: return "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"
        @unknown default: return "0x\(String(format: "%04X", suite.rawValue))"
        }
    }

    static func printCertDetails(
        _ cert: SecCertificate, isLeaf: Bool, verified: Bool?, trustError: CFError?
    ) {
        let oids: [CFString] = [
            kSecOIDX509V1SubjectName,
            kSecOIDX509V1IssuerName,
            kSecOIDX509V1SerialNumber,
            kSecOIDX509V1ValidityNotBefore,
            kSecOIDX509V1ValidityNotAfter,
            kSecOIDSubjectAltName,
        ]

        var cfError: Unmanaged<CFError>?
        guard
            let valuesDict = SecCertificateCopyValues(cert, oids as CFArray, &cfError)
                as? [String: [String: Any]]
        else {
            if let summary = SecCertificateCopySubjectSummary(cert) {
                print("  Subject:    \(summary)")
            }
            return
        }

        // Subject
        if let subject = valuesDict[kSecOIDX509V1SubjectName as String],
            let entries = subject[kSecPropertyKeyValue as String] as? [[String: Any]]
        {
            print("  Subject:    \(formatDN(entries))")
        }

        // Issuer
        if let issuer = valuesDict[kSecOIDX509V1IssuerName as String],
            let entries = issuer[kSecPropertyKeyValue as String] as? [[String: Any]]
        {
            print("  Issuer:     \(formatDN(entries))")
        }

        // Serial number
        if let serial = valuesDict[kSecOIDX509V1SerialNumber as String],
            let value = serial[kSecPropertyKeyValue as String] as? String
        {
            let cleaned = value.replacingOccurrences(of: " ", with: "")
            if let decimal = hexToDecimalString(cleaned) {
                print("  Serial:     \(decimal)")
            } else {
                print("  Serial:     \(value)")
            }
        }

        // Not Before
        if let notBefore = valuesDict[kSecOIDX509V1ValidityNotBefore as String],
            let value = notBefore[kSecPropertyKeyValue as String]
        {
            print("  Not Before: \(formatCertDate(value))")
        }

        // Not After
        if let notAfter = valuesDict[kSecOIDX509V1ValidityNotAfter as String],
            let value = notAfter[kSecPropertyKeyValue as String]
        {
            print("  Not After:  \(formatCertDate(value))")
            if let date = certDateToDate(value) {
                let daysLeft = Int(ceil(date.timeIntervalSinceNow / 86400))
                print("  Expires In: \(daysLeft) days")
            }
        }

        // DNS Names (Subject Alternative Name)
        if let san = valuesDict[kSecOIDSubjectAltName as String],
            let entries = san[kSecPropertyKeyValue as String] as? [[String: Any]]
        {
            let dnsNames = entries.compactMap { entry -> String? in
                guard let label = entry[kSecPropertyKeyLabel as String] as? String,
                    label == "DNS Name",
                    let value = entry[kSecPropertyKeyValue as String] as? String
                else { return nil }
                return value
            }
            if !dnsNames.isEmpty {
                print("  DNS Names:  \(dnsNames.joined(separator: ", "))")
            }
        }

        // Verify status (leaf certificate only)
        if let verified = verified {
            if verified {
                print("  Verify:     OK")
            } else if let error = trustError {
                print("  Verify:     FAILED (\(CFErrorCopyDescription(error) as String))")
            } else {
                print("  Verify:     FAILED")
            }
        }
    }

    private static let dnAbbreviations: [String: String] = [
        "2.5.4.3": "CN",
        "2.5.4.4": "SN",
        "2.5.4.5": "SERIALNUMBER",
        "2.5.4.6": "C",
        "2.5.4.7": "L",
        "2.5.4.8": "ST",
        "2.5.4.10": "O",
        "2.5.4.11": "OU",
        "2.5.4.15": "BUSINESS_CATEGORY",
        "1.3.6.1.4.1.311.60.2.1.2": "STATE_OF_INCORPORATION",
        "1.3.6.1.4.1.311.60.2.1.3": "COUNTRY_OF_INCORPORATION",
    ]

    static func formatDN(_ entries: [[String: Any]]) -> String {
        entries.compactMap { entry -> String? in
            guard let label = entry[kSecPropertyKeyLabel as String] as? String,
                let value = entry[kSecPropertyKeyValue as String]
            else { return nil }
            let abbr = dnAbbreviations[label] ?? label
            return "\(abbr)=\(value)"
        }.joined(separator: ",")
    }

    static func formatCertDate(_ value: Any) -> String {
        if let number = value as? NSNumber {
            let date = Date(timeIntervalSinceReferenceDate: number.doubleValue)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.string(from: date)
        }
        return "\(value)"
    }

    static func certDateToDate(_ value: Any) -> Date? {
        if let number = value as? NSNumber {
            return Date(timeIntervalSinceReferenceDate: number.doubleValue)
        }
        return nil
    }

    /// Convert a hex string to its decimal representation (for large serial numbers)
    static func hexToDecimalString(_ hex: String) -> String? {
        guard !hex.isEmpty else { return nil }
        var result: [UInt8] = []
        for char in hex {
            guard let digit = UInt8(String(char), radix: 16) else { return nil }
            var carry = UInt16(digit)
            for j in stride(from: result.count - 1, through: 0, by: -1) {
                let prod = UInt16(result[j]) * 16 + carry
                result[j] = UInt8(prod % 10)
                carry = prod / 10
            }
            while carry > 0 {
                result.insert(UInt8(carry % 10), at: 0)
                carry /= 10
            }
            if result.isEmpty { result.append(0) }
        }
        if result.isEmpty { return "0" }
        return result.map { String($0) }.joined()
    }

    // MARK: - DNS Inspection

    public static func inspectDNS(host: String) throws {
        print("DNS lookup for \(host)\n")

        // A/AAAA records via getaddrinfo
        let addresses = resolveAddresses(host: host)
        if !addresses.isEmpty {
            print("Addresses:")
            let maxLen = addresses.map(\.0.count).max() ?? 0
            for (addr, version) in addresses {
                let padded = addr.padding(
                    toLength: max(maxLen + 2, 18), withPad: " ", startingAt: 0)
                print("  \(padded)(\(version))")
            }
        }

        // MX records
        let mxRecords = queryMXRecords(host: host)
        if !mxRecords.isEmpty {
            print("\nMX Records:")
            let sorted = mxRecords.sorted { $0.1 < $1.1 }
            let maxLen = sorted.map(\.0.count).max() ?? 0
            for (exchange, priority) in sorted {
                let padded = exchange.padding(
                    toLength: max(maxLen + 2, 21), withPad: " ", startingAt: 0)
                print("  \(padded)priority=\(priority)")
            }
        }

        // TXT records
        let txtRecords = queryTXTRecords(host: host)
        if !txtRecords.isEmpty {
            print("\nTXT Records:")
            for txt in txtRecords {
                let display = txt.count > 80 ? String(txt.prefix(80)) + "..." : txt
                print("  \(display)")
            }
        }

        // NS records
        let nsRecords = queryNSRecords(host: host)
        if !nsRecords.isEmpty {
            print("\nNS Records:")
            for ns in nsRecords {
                print("  \(ns)")
            }
        }

        // CNAME (only shown if it differs from the queried host)
        if let cname = queryCNAMERecord(host: host), cname != host + "." {
            print("\nCNAME: \(cname)")
        }
    }

    static func resolveAddresses(host: String) -> [(String, String)] {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, &hints, &result)
        guard status == 0, let firstResult = result else { return [] }
        defer { freeaddrinfo(firstResult) }

        var addresses: [(String, String)] = []
        var seen = Set<String>()
        var current: UnsafeMutablePointer<addrinfo>? = firstResult

        while let info = current {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(
                info.pointee.ai_addr, info.pointee.ai_addrlen,
                &hostname, socklen_t(hostname.count),
                nil, 0, NI_NUMERICHOST
            ) == 0 {
                let addr = String(cString: hostname)
                if !seen.contains(addr) {
                    seen.insert(addr)
                    let version = info.pointee.ai_family == AF_INET6 ? "IPv6" : "IPv4"
                    addresses.append((addr, version))
                }
            }
            current = info.pointee.ai_next
        }

        return addresses
    }

    // MARK: DNS query helpers (cresolv_query + manual response parsing)

    private static let dnsClassIN: Int32 = 1
    private static let dnsTypeMX: Int32 = 15
    private static let dnsTypeTXT: Int32 = 16
    private static let dnsTypeNS: Int32 = 2
    private static let dnsTypeCNAME: Int32 = 5

    private static func queryDNSRaw(host: String, type: Int32) -> [UInt8]? {
        var answer = [UInt8](repeating: 0, count: 65536)
        let len = cresolv_query(host, dnsClassIN, type, &answer, Int32(answer.count))
        guard len > 0 else { return nil }
        return Array(answer.prefix(Int(len)))
    }

    /// Parse a DNS response and return answer records matching the query type.
    private static func parseDNSAnswers(response: [UInt8], queryType: Int32) -> [(
        rdata: [UInt8], rdataOffset: Int
    )] {
        guard response.count >= 12 else { return [] }

        let qdcount = Int(UInt16(response[4]) << 8 | UInt16(response[5]))
        let ancount = Int(UInt16(response[6]) << 8 | UInt16(response[7]))

        var offset = 12

        // Skip question section
        for _ in 0..<qdcount {
            offset = skipDNSName(response, offset: offset)
            guard offset + 4 <= response.count else { return [] }
            offset += 4  // QTYPE + QCLASS
        }

        // Parse answer section
        var answers: [(rdata: [UInt8], rdataOffset: Int)] = []
        for _ in 0..<ancount {
            offset = skipDNSName(response, offset: offset)
            guard offset + 10 <= response.count else { break }

            let rrtype = Int32(UInt16(response[offset]) << 8 | UInt16(response[offset + 1]))
            offset += 2  // TYPE
            offset += 2  // CLASS
            offset += 4  // TTL
            let rdlength = Int(UInt16(response[offset]) << 8 | UInt16(response[offset + 1]))
            offset += 2

            guard offset + rdlength <= response.count else { break }

            if rrtype == queryType {
                let rdata = Array(response[offset..<(offset + rdlength)])
                answers.append((rdata: rdata, rdataOffset: offset))
            }
            offset += rdlength
        }

        return answers
    }

    /// Skip a DNS name (handles both regular and compressed names)
    private static func skipDNSName(_ bytes: [UInt8], offset: Int) -> Int {
        var off = offset
        while off < bytes.count {
            let len = Int(bytes[off])
            if len == 0 { return off + 1 }
            if len >= 0xC0 { return off + 2 }  // Compressed pointer (2 bytes)
            off += 1 + len
        }
        return off
    }

    /// Expand a possibly-compressed DNS name using cresolv_dn_expand from libresolv
    private static func expandDNSName(response: [UInt8], offset: Int) -> String? {
        var nameBuffer = [CChar](repeating: 0, count: 256)
        let result = response.withUnsafeBufferPointer { buffer -> Int32 in
            guard let base = buffer.baseAddress else { return -1 }
            return cresolv_dn_expand(base, base + response.count, base + offset, &nameBuffer, 256)
        }
        guard result >= 0 else { return nil }
        return String(cString: nameBuffer)
    }

    static func queryMXRecords(host: String) -> [(String, UInt16)] {
        guard let response = queryDNSRaw(host: host, type: dnsTypeMX) else { return [] }
        let answers = parseDNSAnswers(response: response, queryType: dnsTypeMX)

        var results: [(String, UInt16)] = []
        for answer in answers {
            guard answer.rdata.count >= 4 else { continue }
            let priority = UInt16(answer.rdata[0]) << 8 | UInt16(answer.rdata[1])
            // Exchange name starts 2 bytes into the RDATA
            if let name = expandDNSName(response: response, offset: answer.rdataOffset + 2) {
                results.append((name, priority))
            }
        }
        return results
    }

    static func queryTXTRecords(host: String) -> [String] {
        guard let response = queryDNSRaw(host: host, type: dnsTypeTXT) else { return [] }
        let answers = parseDNSAnswers(response: response, queryType: dnsTypeTXT)

        var results: [String] = []
        for answer in answers {
            // TXT RDATA is one or more length-prefixed strings
            var off = 0
            var texts: [String] = []
            while off < answer.rdata.count {
                let len = Int(answer.rdata[off])
                off += 1
                guard off + len <= answer.rdata.count else { break }
                if let text = String(bytes: answer.rdata[off..<(off + len)], encoding: .utf8) {
                    texts.append(text)
                }
                off += len
            }
            results.append(texts.joined())
        }
        return results
    }

    static func queryNSRecords(host: String) -> [String] {
        guard let response = queryDNSRaw(host: host, type: dnsTypeNS) else { return [] }
        let answers = parseDNSAnswers(response: response, queryType: dnsTypeNS)
        return answers.compactMap { expandDNSName(response: response, offset: $0.rdataOffset) }
    }

    static func queryCNAMERecord(host: String) -> String? {
        guard let response = queryDNSRaw(host: host, type: dnsTypeCNAME) else { return nil }
        let answers = parseDNSAnswers(response: response, queryType: dnsTypeCNAME)
        guard let first = answers.first else { return nil }
        return expandDNSName(response: response, offset: first.rdataOffset)
    }

    // MARK: - Help

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
          tls       Inspect TLS certificate chain of a host
          dns       DNS lookup: A/AAAA, MX, TXT, NS, CNAME records

        Options:
          -mode, -m <mode>   Mode (default: check)
          -host <hostname>   Target host (or pass as positional argument)
          -port <n>          Port number (default: 80, or 443 for tls mode)
          -end <n>           End port for scan range
          -timeout <secs>    Connection timeout in seconds (default: 5.0)
          -scan              Scan for nearby networks (wifi mode only)
          -h, --help         Show this help

        Examples:
          swiftswiss net -mode tls apple.com
          swiftswiss net -mode tls -port 8443 myserver.com
          swiftswiss net -mode dns apple.com

        Wi-Fi Notes:
          The wifi mode requires a Mac with a Wi-Fi interface.
          The -scan option requires Location Services to be enabled for your
          terminal app in System Settings > Privacy & Security > Location Services.

        Frameworks: Network (NWConnection, NWPathMonitor), CoreWLAN (CWWiFiClient),
                    Security (SecTrust, SecCertificate)
        """)
    }
}
