import AudioToolbox
import AVFoundation
import CoreMedia
import Foundation

public enum MediaCommand {
    public static func run(_ args: [String]) async throws {
        var filePath: String?
        var mode = "info"

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                filePath = args[i]
            }
            i += 1
        }

        switch mode {
        case "codecs":
            printCodecs()
            return
        case "formats":
            printFormats()
            return
        case "info":
            break
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: info, codecs, formats)")
        }

        guard let path = filePath else { throw SwiftSwissError.missingArgument("media file path") }
        guard FileManager.default.fileExists(atPath: path) else {
            throw SwiftSwissError.fileNotFound(path)
        }

        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)

        let seconds = CMTimeGetSeconds(duration)
        let fileSize = try FileManager.default.attributesOfItem(atPath: path)[.size] as? Int ?? 0

        print("File:     \(path)")
        print("Duration: \(formatDuration(seconds))")
        print("Size:     \(formatBytes(fileSize))")
        print("Tracks:   \(tracks.count)")

        for track in tracks {
            let mediaType = track.mediaType
            print("\n  [\(mediaType.rawValue.uppercased())]")

            if mediaType == .video {
                let size = try await track.load(.naturalSize)
                let frameRate = try await track.load(.nominalFrameRate)
                let bitRate = try await track.load(.estimatedDataRate)
                print("  Resolution: \(Int(size.width))x\(Int(size.height))")
                print("  Frame rate: \(String(format: "%.2f", frameRate)) fps")
                if bitRate > 0 {
                    print("  Bit rate:   \(formatBytes(Int(bitRate / 8)))/s")
                }
            }

            if mediaType == .audio {
                let bitRate = try await track.load(.estimatedDataRate)
                if bitRate > 0 {
                    print("  Bit rate:   \(Int(bitRate / 1000)) kbps")
                }
                let formatDescriptions = try await track.load(.formatDescriptions)
                for desc in formatDescriptions {
                    if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee {
                        print("  Sample rate: \(Int(asbd.mSampleRate)) Hz")
                        print("  Channels:    \(asbd.mChannelsPerFrame)")
                    }
                }
            }
        }

        // Metadata
        let metadata = try await asset.load(.metadata)
        if !metadata.isEmpty {
            print("\nMetadata:")
            for item in metadata {
                if let key = item.commonKey?.rawValue {
                    let value = try? await item.load(.value)
                    if let v = value {
                        print("  \(key): \(v)")
                    }
                }
            }
        }

        // AudioToolbox details for audio files
        printAudioFileDetails(path: path)
    }

    // MARK: - AudioToolbox: file details

    static func printAudioFileDetails(path: String) {
        let url = URL(fileURLWithPath: path) as CFURL
        var audioFile: AudioFileID?
        let status = AudioFileOpenURL(url, .readPermission, 0, &audioFile)
        guard status == noErr, let file = audioFile else { return }
        defer { AudioFileClose(file) }

        print("\nAudio File Properties:")

        var formatID: AudioFormatID = 0
        var formatSize = UInt32(MemoryLayout<AudioFormatID>.size)
        if AudioFileGetProperty(file, kAudioFilePropertyFileFormat, &formatSize, &formatID) == noErr {
            print("  File format:    \(fourCCString(formatID)) (\(formatID))")
        }

        var asbd = AudioStreamBasicDescription()
        var asbdSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        if AudioFileGetProperty(file, kAudioFilePropertyDataFormat, &asbdSize, &asbd) == noErr {
            print("  Data format:    \(fourCCString(asbd.mFormatID))")
            print("  Sample rate:    \(Int(asbd.mSampleRate)) Hz")
            print("  Channels:       \(asbd.mChannelsPerFrame)")
            print("  Bits/channel:   \(asbd.mBitsPerChannel)")
            print("  Bytes/packet:   \(asbd.mBytesPerPacket)")
            print("  Frames/packet:  \(asbd.mFramesPerPacket)")
        }

        var packetCount: UInt64 = 0
        var packetSize = UInt32(MemoryLayout<UInt64>.size)
        if AudioFileGetProperty(file, kAudioFilePropertyAudioDataPacketCount, &packetSize, &packetCount) == noErr {
            print("  Total packets:  \(packetCount)")
        }

        var byteCount: UInt64 = 0
        var byteSize = UInt32(MemoryLayout<UInt64>.size)
        if AudioFileGetProperty(file, kAudioFilePropertyAudioDataByteCount, &byteSize, &byteCount) == noErr {
            print("  Audio data:     \(formatBytes(Int(byteCount)))")
        }

        var estDuration: Float64 = 0
        var durationSize = UInt32(MemoryLayout<Float64>.size)
        if AudioFileGetProperty(file, kAudioFilePropertyEstimatedDuration, &durationSize, &estDuration) == noErr {
            print("  Est. duration:  \(formatDuration(estDuration))")
        }
    }

    static func fourCCString(_ code: UInt32) -> String {
        let chars = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF),
        ]
        return String(chars.map { Character(UnicodeScalar($0)) })
    }

    // MARK: - AudioToolbox: codec enumeration

    static func printCodecs() {
        print("Available Audio Encoders:")
        printCodecList(specifier: kAudioEncoderComponentType)
        print("\nAvailable Audio Decoders:")
        printCodecList(specifier: kAudioDecoderComponentType)
    }

    static func printCodecList(specifier: UInt32) {
        var size: UInt32 = 0

        let propertyID: AudioFormatPropertyID =
            specifier == kAudioEncoderComponentType
            ? kAudioFormatProperty_EncodeFormatIDs
            : kAudioFormatProperty_DecodeFormatIDs

        var status = AudioFormatGetPropertyInfo(propertyID, 0, nil, &size)
        guard status == noErr, size > 0 else {
            print("  (none found)")
            return
        }

        let count = Int(size) / MemoryLayout<AudioFormatID>.size
        var formatIDs = [AudioFormatID](repeating: 0, count: count)
        status = AudioFormatGetProperty(propertyID, 0, nil, &size, &formatIDs)
        guard status == noErr else {
            print("  (error enumerating)")
            return
        }

        for formatID in formatIDs {
            let fourCC = fourCCString(formatID)

            // kAudioFormatProperty_FormatName requires an AudioStreamBasicDescription
            var asbd = AudioStreamBasicDescription()
            asbd.mFormatID = formatID
            var nameSize: UInt32 = 0
            let specSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            let nameStatus = AudioFormatGetPropertyInfo(
                kAudioFormatProperty_FormatName,
                specSize,
                &asbd,
                &nameSize
            )
            if nameStatus == noErr, nameSize > 0 {
                var ns = nameSize
                var nameRef: Unmanaged<CFString>?
                let s = withUnsafeMutablePointer(to: &nameRef) { ptr in
                    AudioFormatGetProperty(
                        kAudioFormatProperty_FormatName,
                        specSize,
                        &asbd,
                        &ns,
                        ptr
                    )
                }
                if s == noErr, let name = nameRef?.takeRetainedValue() {
                    print("  \(fourCC.padding(toLength: 8, withPad: " ", startingAt: 0)) \(name)")
                    continue
                }
            }
            print("  \(fourCC)")
        }
    }

    // MARK: - AudioToolbox: writable format enumeration

    static func printFormats() {
        print("Supported Audio File Formats:")

        var size: UInt32 = 0
        var status = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_WritableTypes, 0, nil, &size)
        guard status == noErr, size > 0 else {
            print("  (could not enumerate)")
            return
        }

        let count = Int(size) / MemoryLayout<AudioFileTypeID>.size
        var types = [AudioFileTypeID](repeating: 0, count: count)
        status = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_WritableTypes, 0, nil, &size, &types)
        guard status == noErr else {
            print("  (error enumerating)")
            return
        }

        for typeID in types {
            let fourCC = fourCCString(typeID)

            // Get the type name
            var nameSize: UInt32 = 0
            var typeIDCopy = typeID
            let specSize = UInt32(MemoryLayout<AudioFileTypeID>.size)
            let nameStatus = AudioFileGetGlobalInfoSize(
                kAudioFileGlobalInfo_FileTypeName,
                specSize,
                &typeIDCopy,
                &nameSize
            )
            if nameStatus == noErr, nameSize > 0 {
                var nameRef: Unmanaged<CFString>?
                let s = withUnsafeMutablePointer(to: &nameRef) { ptr in
                    AudioFileGetGlobalInfo(
                        kAudioFileGlobalInfo_FileTypeName,
                        specSize,
                        &typeIDCopy,
                        &nameSize,
                        ptr
                    )
                }
                if s == noErr, let name = nameRef?.takeRetainedValue() {
                    // Get extensions
                    var extSize: UInt32 = 0
                    let extStatus = AudioFileGetGlobalInfoSize(
                        kAudioFileGlobalInfo_ExtensionsForType,
                        specSize,
                        &typeIDCopy,
                        &extSize
                    )
                    var extStr = ""
                    if extStatus == noErr, extSize > 0 {
                        var extRef: Unmanaged<CFArray>?
                        var es = extSize
                        let s2 = withUnsafeMutablePointer(to: &extRef) { ptr in
                            AudioFileGetGlobalInfo(
                                kAudioFileGlobalInfo_ExtensionsForType,
                                specSize,
                                &typeIDCopy,
                                &es,
                                ptr
                            )
                        }
                        if s2 == noErr, let exts = extRef?.takeRetainedValue() as? [String] {
                            extStr = " (\(exts.joined(separator: ", ")))"
                        }
                    }

                    print("  \(fourCC.padding(toLength: 8, withPad: " ", startingAt: 0)) \(name)\(extStr)")
                    continue
                }
            }
            print("  \(fourCC)")
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss media [-mode <mode>] [file]

        Inspect audio/video file metadata, tracks, and codec information.

        Modes:
          info       Inspect a media file (default)
          codecs     List available audio encoders and decoders
          formats    List supported audio file formats and extensions

        Options:
          -mode <mode>  Processing mode (default: info)
          -h, --help    Show this help

        Supported formats: MP4, MOV, M4A, MP3, WAV, AIFF, CAF, and more.

        Frameworks: AVFoundation, CoreAudio (AudioToolbox)
        """)
    }
}
