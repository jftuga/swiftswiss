import AVFoundation
import Foundation

public enum SpeakCommand {
    public static func run(_ args: [String]) throws {
        var mode = "say"
        var language: String?
        var rate: Float = AVSpeechUtteranceDefaultSpeechRate
        var textArgs: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-lang":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("language") }
                language = args[i]
            case "-rate":
                i += 1; guard i < args.count, let v = Float(args[i]) else {
                    throw SwiftSwissError.missingArgument("rate (number)")
                }
                rate = v
            case "-h", "--help":
                printHelp(); return
            default:
                textArgs.append(args[i])
            }
            i += 1
        }

        switch mode {
        case "say":
            let text: String
            if textArgs.isEmpty {
                text = try readInputString(from: nil).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                text = textArgs.joined(separator: " ")
            }
            guard !text.isEmpty else { throw SwiftSwissError.missingArgument("text to speak") }
            try speak(text: text, language: language, rate: rate)

        case "voices":
            printVoices(language: language)

        default:
            throw SwiftSwissError.invalidOption("unknown mode: \(mode) (choices: say, voices)")
        }
    }

    static func speak(text: String, language: String?, rate: Float) throws {
        let synthesizer = AVSpeechSynthesizer()
        let delegate = SpeechDelegate()
        synthesizer.delegate = delegate

        let utterance = AVSpeechUtterance(string: text)
        if let lang = language {
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
        }
        utterance.rate = rate

        synthesizer.speak(utterance)

        // Process run loop events until speech completes
        let timeout = Date(timeIntervalSinceNow: 300) // 5 minute max
        while !delegate.isFinished && Date() < timeout {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        if !delegate.isFinished {
            throw SwiftSwissError.operationFailed("speech synthesis timed out")
        }
    }

    static func printVoices(language: String?) {
        var voices = AVSpeechSynthesisVoice.speechVoices()
        if let lang = language {
            voices = voices.filter { $0.language.hasPrefix(lang) }
        }
        voices.sort { $0.language < $1.language }

        let langWidth = 8
        let nameWidth = 30
        print("Language".padding(toLength: langWidth, withPad: " ", startingAt: 0),
              "Name".padding(toLength: nameWidth, withPad: " ", startingAt: 0),
              "Quality")
        print(String(repeating: "-", count: langWidth + nameWidth + 10))

        for voice in voices {
            let quality: String
            switch voice.quality {
            case .default: quality = "default"
            case .enhanced: quality = "enhanced"
            case .premium: quality = "premium"
            @unknown default: quality = "unknown"
            }
            print(voice.language.padding(toLength: langWidth, withPad: " ", startingAt: 0),
                  voice.name.padding(toLength: nameWidth, withPad: " ", startingAt: 0),
                  quality)
        }
        print("\nTotal: \(voices.count) voices")
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss speak [options] [text...]

        Text-to-speech synthesis.

        Modes:
          say      Speak the given text (default)
          voices   List available voices

        Options:
          -mode <mode>    Mode (default: say)
          -lang <code>    Voice language (e.g., en-US, fr-FR, de-DE)
          -rate <float>   Speech rate (0.0-1.0, default: ~0.5)
          -h, --help      Show this help

        If no text arguments are given, reads from stdin.

        Frameworks: AVFoundation (AVSpeechSynthesizer)
        """)
    }
}

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var isFinished = false

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isFinished = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isFinished = true
    }
}
