import CoreAudio
import CoreWLAN
import Foundation
import IOKit
import IOKit.ps
import SystemConfiguration

public enum InfoCommand {
    public static func run(_ args: [String]) throws {
        for arg in args {
            if arg == "-h" || arg == "--help" {
                printHelp(); return
            }
        }

        printSystemInfo()
        print()
        printPowerInfo()
        print()
        printNetworkInfo()
        print()
        printDiskInfo()
        print()
        printAudioInfo()
    }

    static func printSystemInfo() {
        let info = ProcessInfo.processInfo

        print("System Information:")
        print("  Hostname:     \(info.hostName)")
        print("  OS Version:   \(info.operatingSystemVersionString)")

        let version = info.operatingSystemVersion
        print("  macOS:        \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)")
        print("  Processors:   \(info.processorCount)")
        print("  Active CPUs:  \(info.activeProcessorCount)")
        print("  Memory:       \(formatBytes(Int(info.physicalMemory)))")
        print("  Uptime:       \(formatDuration(info.systemUptime))")
        print("  Username:     \(NSUserName())")
        print("  Full Name:    \(NSFullUserName())")
        print("  Home:         \(NSHomeDirectory())")
        print("  Temp Dir:     \(NSTemporaryDirectory())")

        // Thermal state
        let thermal: String
        switch info.thermalState {
        case .nominal: thermal = "nominal"
        case .fair: thermal = "fair"
        case .serious: thermal = "serious"
        case .critical: thermal = "critical"
        @unknown default: thermal = "unknown"
        }
        print("  Thermal:      \(thermal)")
        print("  Low Power:    \(info.isLowPowerModeEnabled)")
    }

    // MARK: - Power (IOKit)

    static func printPowerInfo() {
        print("Power Information:")

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty
        else {
            print("  Source: AC Power (no battery detected)")
            return
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue()
                    as? [String: Any] else { continue }

            if let name = desc[kIOPSNameKey] as? String {
                print("  Name:         \(name)")
            }
            if let type = desc[kIOPSTypeKey] as? String {
                print("  Type:         \(type)")
            }
            if let state = desc[kIOPSPowerSourceStateKey] as? String {
                print("  State:        \(state)")
            }
            if let currentCap = desc[kIOPSCurrentCapacityKey] as? Int,
               let maxCap = desc[kIOPSMaxCapacityKey] as? Int {
                let pct = maxCap > 0 ? currentCap * 100 / maxCap : 0
                print("  Capacity:     \(pct)% (\(currentCap)/\(maxCap))")
            }
            if let isCharging = desc[kIOPSIsChargingKey] as? Bool {
                print("  Charging:     \(isCharging)")
            }
            if let timeRemaining = desc[kIOPSTimeToEmptyKey] as? Int, timeRemaining >= 0 {
                print("  Time to empty: \(timeRemaining) min")
            }
            if let timeToFull = desc[kIOPSTimeToFullChargeKey] as? Int, timeToFull >= 0 {
                print("  Time to full: \(timeToFull) min")
            }
        }
    }

    // MARK: - Network (SystemConfiguration)

    static func printNetworkInfo() {
        print("Network Information:")

        if let computerName = SCDynamicStoreCopyComputerName(nil, nil) as? String {
            print("  Computer Name: \(computerName)")
        }
        if let localHost = SCDynamicStoreCopyLocalHostName(nil) as? String {
            print("  Local Host:    \(localHost).local")
        }

        if let iface = CWWiFiClient.shared().interface() {
            if let ssid = iface.ssid() {
                print("  Wi-Fi SSID:    \(ssid)")
            } else if iface.rssiValue() != 0 {
                print("  Wi-Fi SSID:    (enable Location Services to display)")
            }
        }

        // Check reachability for a few well-known hosts
        let hosts = ["apple.com", "google.com", "1.1.1.1"]
        for host in hosts {
            let reachable = checkReachability(host: host)
            print("  \(host): \(reachable ? "reachable" : "unreachable")")
        }

        // Proxy configuration
        if let proxies = SCDynamicStoreCopyProxies(nil) as? [String: Any] {
            if let httpProxy = proxies[kSCPropNetProxiesHTTPProxy as String] as? String {
                let port = proxies[kSCPropNetProxiesHTTPPort as String] as? Int ?? 0
                print("  HTTP Proxy:   \(httpProxy):\(port)")
            }
            if let httpsProxy = proxies[kSCPropNetProxiesHTTPSProxy as String] as? String {
                let port = proxies[kSCPropNetProxiesHTTPSPort as String] as? Int ?? 0
                print("  HTTPS Proxy:  \(httpsProxy):\(port)")
            }
        }
    }

    public static func checkReachability(host: String) -> Bool {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return false
        }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return false
        }
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }

    static func printDiskInfo() {
        print("Disk Information:")
        let fileManager = FileManager.default
        let homeDir = NSHomeDirectory()

        do {
            let attrs = try fileManager.attributesOfFileSystem(forPath: homeDir)
            if let totalSize = attrs[.systemSize] as? Int {
                print("  Total:     \(formatBytes(totalSize))")
            }
            if let freeSize = attrs[.systemFreeSize] as? Int {
                print("  Free:      \(formatBytes(freeSize))")
            }
            if let nodes = attrs[.systemNodes] as? Int {
                print("  Nodes:     \(nodes)")
            }
        } catch {
            print("  (could not read disk info: \(error.localizedDescription))")
        }
    }

    // MARK: - Audio (CoreAudio)

    static func printAudioInfo() {
        print("Audio Devices:")

        guard let deviceIDs = getAudioDeviceIDs() else {
            print("  (no audio devices found)")
            return
        }

        let defaultOutput = getDefaultAudioDevice(forInput: false)
        let defaultInput = getDefaultAudioDevice(forInput: true)

        for deviceID in deviceIDs {
            guard let name = getAudioDeviceName(deviceID) else { continue }

            let inputChannels = getAudioDeviceChannelCount(deviceID, forInput: true)
            let outputChannels = getAudioDeviceChannelCount(deviceID, forInput: false)

            var direction = ""
            if inputChannels > 0 && outputChannels > 0 { direction = "input/output" }
            else if inputChannels > 0 { direction = "input" }
            else if outputChannels > 0 { direction = "output" }
            else { continue }  // skip devices with no channels

            var markers: [String] = []
            if deviceID == defaultOutput { markers.append("default output") }
            if deviceID == defaultInput { markers.append("default input") }
            let markerStr = markers.isEmpty ? "" : " (\(markers.joined(separator: ", ")))"

            print("  \(name)\(markerStr)")
            print("    Direction:  \(direction)")

            if let transport = getAudioDeviceTransportType(deviceID) {
                print("    Transport:  \(transport)")
            }

            if let manufacturer = getAudioDeviceManufacturer(deviceID) {
                print("    Maker:      \(manufacturer)")
            }

            if inputChannels > 0 {
                print("    In Ch:      \(inputChannels)")
            }
            if outputChannels > 0 {
                print("    Out Ch:     \(outputChannels)")
            }

            if let sampleRate = getAudioDeviceSampleRate(deviceID) {
                print("    Rate:       \(Int(sampleRate)) Hz")
            }

            if let volume = getAudioDeviceVolume(deviceID) {
                print("    Volume:     \(Int(volume * 100))%")
            }
        }
    }

    static func getAudioDeviceIDs() -> [AudioDeviceID]? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        )
        guard status == noErr, dataSize > 0 else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs
        )
        guard status == noErr else { return nil }
        return deviceIDs
    }

    static func getDefaultAudioDevice(forInput: Bool) -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: forInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }

    static func getAudioDeviceName(_ deviceID: AudioDeviceID) -> String? {
        return getAudioStringProperty(deviceID, selector: kAudioObjectPropertyName)
    }

    static func getAudioDeviceManufacturer(_ deviceID: AudioDeviceID) -> String? {
        guard let result = getAudioStringProperty(deviceID, selector: kAudioObjectPropertyManufacturer) else {
            return nil
        }
        return result.isEmpty ? nil : result
    }

    private static func getAudioStringProperty(_ deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) == noErr else {
            return nil
        }
        var name: Unmanaged<CFString>?
        let status = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, ptr)
        }
        guard status == noErr, let cfName = name?.takeRetainedValue() else { return nil }
        return cfName as String
    }

    static func getAudioDeviceTransportType(_ deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &transport)
        guard status == noErr else { return nil }

        switch transport {
        case kAudioDeviceTransportTypeBuiltIn:      return "Built-in"
        case kAudioDeviceTransportTypeUSB:           return "USB"
        case kAudioDeviceTransportTypeBluetooth:     return "Bluetooth"
        case kAudioDeviceTransportTypeBluetoothLE:   return "Bluetooth LE"
        case kAudioDeviceTransportTypeHDMI:          return "HDMI"
        case kAudioDeviceTransportTypeDisplayPort:   return "DisplayPort"
        case kAudioDeviceTransportTypeFireWire:      return "FireWire"
        case kAudioDeviceTransportTypeThunderbolt:   return "Thunderbolt"
        case kAudioDeviceTransportTypeVirtual:       return "Virtual"
        case kAudioDeviceTransportTypeAggregate:     return "Aggregate"
        default:                                     return "Other"
        }
    }

    static func getAudioDeviceChannelCount(_ deviceID: AudioDeviceID, forInput: Bool) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: forInput ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return 0 }

        let bufferListPtr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferListPtr.deallocate() }

        status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferListPtr)
        guard status == noErr else { return 0 }

        let bufferList = UnsafeMutableAudioBufferListPointer(bufferListPtr)
        var channels = 0
        for buffer in bufferList {
            channels += Int(buffer.mNumberChannels)
        }
        return channels
    }

    static func getAudioDeviceSampleRate(_ deviceID: AudioDeviceID) -> Float64? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var sampleRate: Float64 = 0
        var dataSize = UInt32(MemoryLayout<Float64>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &sampleRate)
        guard status == noErr, sampleRate > 0 else { return nil }
        return sampleRate
    }

    static func getAudioDeviceVolume(_ deviceID: AudioDeviceID) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        if !AudioObjectHasProperty(deviceID, &address) {
            address.mElement = 1
            guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        }
        var volume: Float32 = 0
        var dataSize = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &volume)
        guard status == noErr else { return nil }
        return volume
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss info

        Display system, power, network, disk, and audio device information.

        Options:
          -h, --help    Show this help

        Frameworks: Foundation (ProcessInfo), IOKit (power sources), SystemConfiguration (reachability), CoreAudio (audio devices), CoreWLAN (Wi-Fi SSID)
        """)
    }
}
