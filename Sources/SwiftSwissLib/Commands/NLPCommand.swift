import Foundation
import NaturalLanguage

public enum NLPCommand {
    public static func run(_ args: [String]) throws {
        var mode = "detect"
        var inlineText: String?
        var files: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "-mode", "-m":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("mode") }
                mode = args[i]
            case "-t":
                i += 1; guard i < args.count else { throw SwiftSwissError.missingArgument("text") }
                inlineText = args[i]
            case "-h", "--help":
                printHelp(); return
            default:
                files.append(args[i])
            }
            i += 1
        }

        if inlineText != nil && !files.isEmpty {
            throw SwiftSwissError.invalidOption("-t cannot be used with file arguments")
        }

        let text: String
        if let inline = inlineText {
            text = inline
        } else {
            if files.isEmpty { files = ["-"] }
            let file = files[0]
            text = try readInputString(from: file == "-" ? nil : file).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !text.isEmpty else { throw SwiftSwissError.missingArgument("text input") }

        switch mode {
        case "detect":
            printLanguageDetection(text)
        case "sentiment":
            printSentiment(text)
        case "entities":
            printEntities(text)
        case "pos":
            printPartsOfSpeech(text)
        case "tokenize":
            printTokens(text)
        case "lemma":
            printLemmas(text)
        default:
            throw SwiftSwissError.invalidOption(
                "unknown mode: \(mode) (choices: detect, sentiment, entities, pos, tokenize, lemma)")
        }
    }

    public static func detectLanguage(_ text: String) -> [(NLLanguage, Double)] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        return hypotheses.sorted { $0.value > $1.value }
    }

    static func printLanguageDetection(_ text: String) {
        let results = detectLanguage(text)
        if results.isEmpty {
            print("Could not detect language")
            return
        }
        print("Language Detection:")
        for (lang, confidence) in results {
            let name = Locale.current.localizedString(forLanguageCode: lang.rawValue) ?? lang.rawValue
            print("  \(name) (\(lang.rawValue)): \(String(format: "%.1f%%", confidence * 100))")
        }
    }

    public static func analyzeSentiment(_ text: String) -> Double? {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return tag.flatMap { Double($0.rawValue) }
    }

    static func printSentiment(_ text: String) {
        if let score = analyzeSentiment(text) {
            let label: String
            if score > 0.1 { label = "Positive" }
            else if score < -0.1 { label = "Negative" }
            else { label = "Neutral" }
            print("Sentiment: \(label) (score: \(String(format: "%.3f", score)))")
        } else {
            print("Could not determine sentiment")
        }
    }

    public static func extractEntities(_ text: String) -> [(String, NLTag)] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        var results: [(String, NLTag)] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, tag != .otherWord {
                results.append((String(text[range]), tag))
            }
            return true
        }
        return results
    }

    static func printEntities(_ text: String) {
        let entities = extractEntities(text)
        if entities.isEmpty {
            print("No named entities found")
            return
        }
        print("Named Entities:")
        for (word, tag) in entities {
            let typeName: String
            switch tag {
            case .personalName: typeName = "Person"
            case .placeName: typeName = "Place"
            case .organizationName: typeName = "Organization"
            default: typeName = tag.rawValue
            }
            print("  \(word) → \(typeName)")
        }
    }

    static func printPartsOfSpeech(_ text: String) {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        print("Parts of Speech:")
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if let tag = tag {
                let word = String(text[range])
                print("  \(word) → \(tag.rawValue)")
            }
            return true
        }
    }

    public static func tokenize(_ text: String, unit: NLTokenUnit = .word) -> [String] {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }

    static func printTokens(_ text: String) {
        print("Word tokens:")
        for token in tokenize(text, unit: .word) {
            print("  \(token)")
        }
        print("\nSentence tokens:")
        for sentence in tokenize(text, unit: .sentence) {
            print("  \(sentence)")
        }
    }

    static func printLemmas(_ text: String) {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        print("Lemmatization:")
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            let word = String(text[range])
            let lemma = tag?.rawValue ?? word
            if lemma != word {
                print("  \(word) → \(lemma)")
            } else {
                print("  \(word)")
            }
            return true
        }
    }

    static func printHelp() {
        print("""
        Usage: swiftswiss nlp -mode <mode> [options] [file]

        Natural language processing on text input.

        Modes:
          detect     Detect the language of the text
          sentiment  Analyze sentiment (positive/negative/neutral)
          entities   Extract named entities (people, places, organizations)
          pos        Tag parts of speech (noun, verb, adjective, etc.)
          tokenize   Tokenize text into words and sentences
          lemma      Reduce words to their base/dictionary form

        Input is read from a file if specified, or from stdin otherwise.
        Use -t to provide text directly (mutually exclusive with file/stdin).

        Options:
          -mode, -m <mode>  Processing mode (default: detect)
          -t <text>      Provide text directly instead of reading from file/stdin
          -h, --help     Show this help

        Frameworks: NaturalLanguage
        """)
    }
}
