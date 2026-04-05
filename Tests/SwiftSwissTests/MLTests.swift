@testable import SwiftSwissLib
import CoreML
import XCTest

final class MLTests: XCTestCase {

    // MARK: - Feature type string mapping

    func testFeatureTypeStringDouble() {
        XCTAssertEqual(MLCommand.featureTypeString(.double), "Double")
    }

    func testFeatureTypeStringInt64() {
        XCTAssertEqual(MLCommand.featureTypeString(.int64), "Int64")
    }

    func testFeatureTypeStringString() {
        XCTAssertEqual(MLCommand.featureTypeString(.string), "String")
    }

    func testFeatureTypeStringImage() {
        XCTAssertEqual(MLCommand.featureTypeString(.image), "Image")
    }

    func testFeatureTypeStringMultiArray() {
        XCTAssertEqual(MLCommand.featureTypeString(.multiArray), "MultiArray")
    }

    func testFeatureTypeStringDictionary() {
        XCTAssertEqual(MLCommand.featureTypeString(.dictionary), "Dictionary")
    }

    func testFeatureTypeStringSequence() {
        XCTAssertEqual(MLCommand.featureTypeString(.sequence), "Sequence")
    }

    // MARK: - Format feature value

    func testFormatFeatureValueDouble() {
        let val = MLFeatureValue(double: 3.14)
        let result = MLCommand.formatFeatureValue(val)
        XCTAssertTrue(result.contains("3.14"))
    }

    func testFormatFeatureValueInt64() {
        let val = MLFeatureValue(int64: 42)
        XCTAssertEqual(MLCommand.formatFeatureValue(val), "42")
    }

    func testFormatFeatureValueString() {
        let val = MLFeatureValue(string: "hello")
        XCTAssertEqual(MLCommand.formatFeatureValue(val), "hello")
    }

    // MARK: - Error paths

    func testMissingModelPath() {
        XCTAssertThrowsError(try MLCommand.run([])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("model path"))
        }
    }

    func testModelFileNotFound() {
        XCTAssertThrowsError(try MLCommand.run(["-model", "/nonexistent/model.mlmodel"])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("not found"))
        }
    }

    func testPredictMissingInputs() {
        // Create a temp file so the "file not found" check passes,
        // but it's not a real model, so compile will fail
        let tmpDir = NSTemporaryDirectory()
        let fakePath = (tmpDir as NSString).appendingPathComponent("fake_\(UUID().uuidString).mlmodel")
        FileManager.default.createFile(atPath: fakePath, contents: Data())
        defer { try? FileManager.default.removeItem(atPath: fakePath) }

        // This should fail during compile (not a valid model), which is expected
        XCTAssertThrowsError(
            try MLCommand.run(["-mode", "predict", "-model", fakePath, "-input", "x=1.0"])
        )
    }

    func testInvalidMode() {
        XCTAssertThrowsError(try MLCommand.run(["-mode", "bogus", "foo.mlmodel"])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("unknown mode"))
        }
    }

    func testInfoOnNonexistentModel() {
        XCTAssertThrowsError(try MLCommand.getModelInfo(path: "/no/such/model.mlmodel")) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("not found"))
        }
    }

    func testHelpFlag() throws {
        let output = try captureStdout {
            try MLCommand.run(["-h"])
        }
        XCTAssertTrue(output.contains("CoreML"))
        XCTAssertTrue(output.contains("info"))
        XCTAssertTrue(output.contains("predict"))
    }

    // MARK: - Input parsing errors

    func testInvalidInputFormat() {
        // buildFeatureProvider expects key=value
        XCTAssertThrowsError(
            try MLCommand.buildFeatureProvider(from: ["noequalssign"], schema: [:])
        ) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("key=value"))
        }
    }

    func testUnknownInputKey() {
        let schema: [String: MLFeatureDescription] = [:]  // empty schema
        XCTAssertThrowsError(
            try MLCommand.buildFeatureProvider(from: ["x=1.0"], schema: schema)
        ) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("unknown input"))
        }
    }
}
