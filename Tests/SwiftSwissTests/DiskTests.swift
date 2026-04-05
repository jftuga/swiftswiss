@testable import SwiftSwissLib
import XCTest

final class DiskTests: XCTestCase {

    // MARK: - List volumes

    func testGetVolumesReturnsResults() throws {
        let volumes = try DiskCommand.getVolumes()
        XCTAssertFalse(volumes.isEmpty, "Every Mac should have at least one mounted volume")
    }

    func testRootVolumePresent() throws {
        let volumes = try DiskCommand.getVolumes()
        let hasRoot = volumes.contains { $0.mountPoint == "/" }
        XCTAssertTrue(hasRoot, "Root volume (/) should be in the list")
    }

    func testRootVolumeHasSize() throws {
        let volumes = try DiskCommand.getVolumes()
        guard let root = volumes.first(where: { $0.mountPoint == "/" }) else {
            XCTFail("Root volume not found"); return
        }
        XCTAssertNotNil(root.totalSize)
        XCTAssertNotNil(root.freeSpace)
        if let total = root.totalSize {
            XCTAssertGreaterThan(total, 0)
        }
    }

    func testRootVolumeHasBSDName() throws {
        let volumes = try DiskCommand.getVolumes()
        guard let root = volumes.first(where: { $0.mountPoint == "/" }) else {
            XCTFail("Root volume not found"); return
        }
        XCTAssertNotEqual(root.bsdName, "unknown")
        XCTAssertFalse(root.bsdName.isEmpty)
    }

    func testRootVolumeHasFilesystem() throws {
        let volumes = try DiskCommand.getVolumes()
        guard let root = volumes.first(where: { $0.mountPoint == "/" }) else {
            XCTFail("Root volume not found"); return
        }
        XCTAssertNotEqual(root.fileSystem, "unknown")
    }

    func testVolumeDescription() throws {
        let volumes = try DiskCommand.getVolumes()
        guard let root = volumes.first(where: { $0.mountPoint == "/" }) else {
            XCTFail("Root volume not found"); return
        }
        let desc = root.description
        XCTAssertTrue(desc.contains("BSD Name:"))
        XCTAssertTrue(desc.contains("Mount Point:"))
        XCTAssertTrue(desc.contains("Filesystem:"))
    }

    // MARK: - CLI output

    func testListOutput() throws {
        let output = try captureStdout {
            try DiskCommand.run(["-mode", "list"])
        }
        XCTAssertTrue(output.contains("Mounted Volumes"))
        XCTAssertTrue(output.contains("BSD Name:"))
        XCTAssertTrue(output.contains("/"))
    }

    func testDefaultModeIsList() throws {
        let output = try captureStdout {
            try DiskCommand.run([])
        }
        XCTAssertTrue(output.contains("Mounted Volumes"))
    }

    // MARK: - Error paths

    func testInvalidMode() {
        XCTAssertThrowsError(try DiskCommand.run(["-mode", "bogus"])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("unknown mode"))
        }
    }

    func testInvalidOption() {
        XCTAssertThrowsError(try DiskCommand.run(["--bogus"])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("unknown option"))
        }
    }

    func testInvalidTimeout() {
        XCTAssertThrowsError(try DiskCommand.run(["-timeout", "abc"])) { error in
            let msg = "\(error)"
            XCTAssertTrue(msg.contains("timeout"))
        }
    }

    func testHelpFlag() throws {
        let output = try captureStdout {
            try DiskCommand.run(["-h"])
        }
        XCTAssertTrue(output.contains("DiskArbitration"))
        XCTAssertTrue(output.contains("list"))
        XCTAssertTrue(output.contains("watch"))
    }

    // MARK: - Volume info flags

    func testRootVolumeIsNotRemovable() throws {
        let volumes = try DiskCommand.getVolumes()
        guard let root = volumes.first(where: { $0.mountPoint == "/" }) else {
            XCTFail("Root volume not found"); return
        }
        XCTAssertFalse(root.isRemovable)
        XCTAssertFalse(root.isEjectable)
        XCTAssertFalse(root.isNetwork)
    }
}
