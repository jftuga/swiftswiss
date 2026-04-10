import DiskArbitration
import Foundation

public enum DiskCommand {
    public static func run(_ args: [String]) throws {
        var mode = "list"
        var timeout: TimeInterval = 10

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-timeout":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("timeout") }
                guard let t = TimeInterval(args[i]) else {
                    throw SwiftSwissError.invalidOption("timeout must be a number")
                }
                timeout = t
            case "-h", "--help":
                printHelp(); return
            default:
                throw SwiftSwissError.invalidOption("unknown option: \(args[i])")
            }
            i += 1
        }

        switch mode {
        case "list":
            try listVolumes()
        case "watch":
            try watchEvents(timeout: timeout)
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: list, watch)")
        }
    }

    // MARK: - List volumes

    public struct VolumeInfo: CustomStringConvertible {
        public let bsdName: String
        public let volumeName: String
        public let mountPoint: String
        public let fileSystem: String
        public let totalSize: Int?
        public let freeSpace: Int?
        public let isRemovable: Bool
        public let isEjectable: Bool
        public let isNetwork: Bool
        public let mediaType: String?

        public var description: String {
            var lines = [String]()
            lines.append("  BSD Name:    \(bsdName)")
            lines.append("  Volume:      \(volumeName)")
            lines.append("  Mount Point: \(mountPoint)")
            lines.append("  Filesystem:  \(fileSystem)")
            if let total = totalSize {
                lines.append("  Total Size:  \(formatBytes(total))")
            }
            if let free = freeSpace {
                lines.append("  Free Space:  \(formatBytes(free))")
            }
            if let total = totalSize, let free = freeSpace, total > 0 {
                let usedPct = Double(total - free) / Double(total) * 100
                lines.append("  Used:        \(String(format: "%.1f%%", usedPct))")
            }
            var flags = [String]()
            if isRemovable { flags.append("removable") }
            if isEjectable { flags.append("ejectable") }
            if isNetwork { flags.append("network") }
            if !flags.isEmpty {
                lines.append("  Flags:       \(flags.joined(separator: ", "))")
            }
            if let media = mediaType, !media.isEmpty {
                lines.append("  Media Type:  \(media)")
            }
            return lines.joined(separator: "\n")
        }
    }

    public static func getVolumes() throws -> [VolumeInfo] {
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            throw SwiftSwissError.operationFailed("could not create DiskArbitration session")
        }

        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey,
                                       .volumeAvailableCapacityKey]
        guard let mountedVolumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [])
        else {
            return []
        }

        var volumes = [VolumeInfo]()
        for volumeURL in mountedVolumes {
            let mountPoint = volumeURL.path
            guard let resources = try? volumeURL.resourceValues(
                forKeys: Set(keys)) else { continue }

            let volumeName = resources.volumeName ?? volumeURL.lastPathComponent

            // Get DiskArbitration info for this mount point
            var bsdName = "unknown"
            var fileSystem = "unknown"
            var isRemovable = false
            var isEjectable = false
            var isNetwork = false
            var mediaType: String?
            var daTotal: Int?

            if let disk = DADiskCreateFromVolumePath(
                kCFAllocatorDefault, session, volumeURL as CFURL) {
                if let desc = DADiskCopyDescription(disk) as? [String: Any] {
                    if let bsd = desc[kDADiskDescriptionMediaBSDNameKey as String] as? String {
                        bsdName = bsd
                    }
                    if let fs = desc[kDADiskDescriptionVolumeKindKey as String] as? String {
                        fileSystem = fs
                    }
                    if let removable = desc[kDADiskDescriptionMediaRemovableKey as String] as? Bool {
                        isRemovable = removable
                    }
                    if let ejectable = desc[kDADiskDescriptionMediaEjectableKey as String] as? Bool {
                        isEjectable = ejectable
                    }
                    if let network = desc[kDADiskDescriptionVolumeNetworkKey as String] as? Bool {
                        isNetwork = network
                    }
                    if let media = desc[kDADiskDescriptionMediaTypeKey as String] as? String {
                        mediaType = media
                    }
                    if let size = desc[kDADiskDescriptionMediaSizeKey as String] as? Int {
                        daTotal = size
                    }
                }
            }

            let totalSize = daTotal ?? resources.volumeTotalCapacity
            let freeSpace = resources.volumeAvailableCapacity

            volumes.append(VolumeInfo(
                bsdName: bsdName,
                volumeName: volumeName,
                mountPoint: mountPoint,
                fileSystem: fileSystem,
                totalSize: totalSize,
                freeSpace: freeSpace,
                isRemovable: isRemovable,
                isEjectable: isEjectable,
                isNetwork: isNetwork,
                mediaType: mediaType
            ))
        }

        return volumes
    }

    static func listVolumes() throws {
        let volumes = try getVolumes()
        if volumes.isEmpty {
            print("No mounted volumes found.")
            return
        }

        print("Mounted Volumes (\(volumes.count)):\n")
        for (i, vol) in volumes.enumerated() {
            print(vol)
            if i < volumes.count - 1 { print() }
        }
    }

    // MARK: - Watch events

    static func watchEvents(timeout: TimeInterval) throws {
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            throw SwiftSwissError.operationFailed("could not create DiskArbitration session")
        }

        print("Watching disk events for \(Int(timeout)) seconds... (Ctrl-C to stop)\n")

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(
            DiskWatchContext()).toOpaque())

        DARegisterDiskAppearedCallback(
            session, nil, diskAppearedCallback, context)
        DARegisterDiskDisappearedCallback(
            session, nil, diskDisappearedCallback, context)
        DARegisterDiskDescriptionChangedCallback(
            session, nil, nil, diskChangedCallback, context)

        DASessionScheduleWithRunLoop(
            session, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        // Run for the specified timeout
        CFRunLoopRunInMode(.defaultMode, timeout, false)

        DASessionUnscheduleFromRunLoop(
            session, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        print("\nDone watching.")
    }

    static func describeDisk(_ disk: DADisk) -> String {
        guard let desc = DADiskCopyDescription(disk) as? [String: Any] else {
            return "unknown disk"
        }
        let bsd = desc[kDADiskDescriptionMediaBSDNameKey as String] as? String ?? "unknown"
        let name = desc[kDADiskDescriptionVolumeNameKey as String] as? String
        if let name = name {
            return "\(bsd) (\(name))"
        }
        return bsd
    }
}

// Callbacks must be top-level or static C-compatible functions
private class DiskWatchContext {}

private func diskAppearedCallback(
    _ disk: DADisk, _ context: UnsafeMutableRawPointer?
) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("[\(ts)] APPEARED: \(DiskCommand.describeDisk(disk))")
}

private func diskDisappearedCallback(
    _ disk: DADisk, _ context: UnsafeMutableRawPointer?
) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("[\(ts)] DISAPPEARED: \(DiskCommand.describeDisk(disk))")
}

private func diskChangedCallback(
    _ disk: DADisk, _ keys: CFArray, _ context: UnsafeMutableRawPointer?
) {
    let ts = ISO8601DateFormatter().string(from: Date())
    let changedKeys = keys as? [String] ?? []
    print("[\(ts)] CHANGED: \(DiskCommand.describeDisk(disk)) keys=\(changedKeys)")
}

extension DiskCommand {
    static func printHelp() {
        print("""
        Usage: swiftswiss disk [options]

        List mounted volumes and watch for disk mount/unmount events.

        Modes:
          list        List all mounted volumes with details (default)
          watch       Watch for disk appear/disappear/change events

        Options:
          -mode, -m <mode>   Mode (default: list)
          -timeout <secs>    Watch duration in seconds (default: 10)
          -h, --help         Show this help

        Examples:
          swiftswiss disk
          swiftswiss disk -mode list
          swiftswiss disk -mode watch
          swiftswiss disk -mode watch -timeout 30

        Frameworks: DiskArbitration
        """)
    }
}
