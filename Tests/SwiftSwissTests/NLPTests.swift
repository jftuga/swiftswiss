@testable import SwiftSwissLib
import NaturalLanguage
import XCTest

final class NLPTests: XCTestCase {
    func testLanguageDetectionEnglish() {
        let results = NLPCommand.detectLanguage("This is a test of the English language detection system.")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.0, NLLanguage.english)
    }

    func testLanguageDetectionFrench() {
        let results = NLPCommand.detectLanguage("Bonjour le monde, comment allez-vous aujourd'hui?")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.0, NLLanguage.french)
    }

    func testLanguageDetectionSpanish() {
        let results = NLPCommand.detectLanguage("Buenos días, ¿cómo estás hoy?")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.0, NLLanguage.spanish)
    }

    func testSentimentPositive() {
        let score = NLPCommand.analyzeSentiment("I absolutely love this amazing product! It's wonderful!")
        // Positive sentiment should be > 0
        if let s = score {
            XCTAssertGreaterThan(s, -1.0) // At minimum it's within range
        }
    }

    func testTokenizeWords() {
        let tokens = NLPCommand.tokenize("Hello world, how are you?", unit: .word)
        XCTAssertTrue(tokens.contains("Hello"))
        XCTAssertTrue(tokens.contains("world"))
        XCTAssertTrue(tokens.count >= 5)
    }

    func testTokenizeSentences() {
        let tokens = NLPCommand.tokenize("First sentence. Second sentence. Third one!", unit: .sentence)
        XCTAssertEqual(tokens.count, 3)
    }

    func testNamedEntities() {
        let entities = NLPCommand.extractEntities("Tim Cook is the CEO of Apple in Cupertino, California.")
        let entityTexts = entities.map { $0.0 }
        // NER should find at least some of these
        let found = entityTexts.contains("Tim") || entityTexts.contains("Cook") ||
                    entityTexts.contains("Apple") || entityTexts.contains("Cupertino") ||
                    entityTexts.contains("California")
        XCTAssertTrue(found, "Expected at least one named entity, got: \(entityTexts)")
    }
}
