import XCTest
@testable import BLZTar

final class BLZTarTests: XCTestCase {
    func testArchiveMultipleSelectedFiles() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceA = root.appendingPathComponent("sourceA")
        let sourceB = root.appendingPathComponent("sourceB")
        let extractDir = root.appendingPathComponent("extract")
        try fm.createDirectory(at: sourceA, withIntermediateDirectories: true)
        try fm.createDirectory(at: sourceB, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let firstFile = sourceA.appendingPathComponent("first.txt")
        let secondFile = sourceB.appendingPathComponent("second.txt")
        try "first".data(using: .utf8)?.write(to: firstFile)
        try "second".data(using: .utf8)?.write(to: secondFile)

        let archiveURL = root.appendingPathComponent("selected-files.tar")
        try BLZTar.archive(files: [firstFile, secondFile], to: archiveURL)
        try BLZTar.extract(archive: archiveURL, toDirectory: extractDir)

        XCTAssertEqual(try String(contentsOf: extractDir.appendingPathComponent("first.txt")), "first")
        XCTAssertEqual(try String(contentsOf: extractDir.appendingPathComponent("second.txt")), "second")
        XCTAssertFalse(fm.fileExists(atPath: extractDir.appendingPathComponent("sourceA").path))
        XCTAssertFalse(fm.fileExists(atPath: extractDir.appendingPathComponent("sourceB").path))
    }

    func testArchiveMultipleSelectedFilesRejectsDuplicateArchiveNames() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceA = root.appendingPathComponent("sourceA")
        let sourceB = root.appendingPathComponent("sourceB")
        try fm.createDirectory(at: sourceA, withIntermediateDirectories: true)
        try fm.createDirectory(at: sourceB, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let firstFile = sourceA.appendingPathComponent("same.txt")
        let secondFile = sourceB.appendingPathComponent("same.txt")
        try "first".data(using: .utf8)?.write(to: firstFile)
        try "second".data(using: .utf8)?.write(to: secondFile)

        XCTAssertThrowsError(try BLZTar.archive(files: [firstFile, secondFile],
                                                to: root.appendingPathComponent("duplicate.tar")))
    }
    func testArchiveCanBeCancelledFromProgressCallback() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceDir = root.appendingPathComponent("source")
        try fm.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let largeFile = sourceDir.appendingPathComponent("large.bin")
        let data = Data(repeating: 0x41, count: 1024 * 1024)
        try data.write(to: largeFile)

        let archiveURL = root.appendingPathComponent("cancelled.tar")
        let options = BLZTarArchiveOptions(onProgressBytes: { _, _ in
            BLZTar.cancel()
        }, reportGranularityBytes: 1)

        XCTAssertThrowsError(try BLZTar.archive(files: [largeFile], to: archiveURL, options: options))
        XCTAssertFalse(fm.fileExists(atPath: archiveURL.path))
    }
}
