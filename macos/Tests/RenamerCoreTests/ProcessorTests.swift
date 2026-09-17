import XCTest
import Foundation
import ZIPFoundation
@testable import RenamerCore

final class ProcessorTests: XCTestCase {
    private var directory: URL!
    private var config: Configuration!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        config = try Configuration.bundled()
        config.mappings = ["en": "english.json", "tr": "turkish.json"]
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }

    @discardableResult private func zip(_ entries: [(String, String)], name: String = "input.zip") throws -> URL {
        let url = directory.appendingPathComponent(name)
        let archive = try Archive(url: url, accessMode: .create)
        for (path, content) in entries {
            let data = Data(content.utf8)
            try archive.addEntry(with: path, type: path.hasSuffix("/") ? .directory : .file,
                                 uncompressedSize: Int64(data.count), compressionMethod: .deflate) { offset, size in
                data.subdata(in: Int(offset)..<Int(offset) + size)
            }
        }
        return url
    }
    private func contents(_ url: URL) throws -> [String: Data] {
        let archive = try Archive(url: url, accessMode: .read)
        var result = [String: Data]()
        for entry in archive where entry.type != .directory {
            var data = Data()
            let crc = try archive.extract(entry) { data.append($0) }
            XCTAssertEqual(crc, entry.checksum)
            result[entry.path] = data
        }
        return result
    }

    func testNestedUnicodeAndPreservedFiles() throws {
        let source = try zip([("nested/EN.json", "{\"hello\":\"Hello\"}"), ("tr.json", "İçerik değişmez 🌿"), ("assets/info.txt", "preserve"), ("empty/", "")])
        let original = try Data(contentsOf: source)
        let plan = try Processor.inspect(source, config: config)
        XCTAssertEqual(plan.renamed.count, 2)
        XCTAssertEqual(plan.preserved.count, 1)
        let output = directory.appendingPathComponent("output.zip")
        try Processor.export(plan, to: output)
        XCTAssertEqual(try contents(output), ["nested/english.json": Data("{\"hello\":\"Hello\"}".utf8), "turkish.json": Data("İçerik değişmez 🌿".utf8), "assets/info.txt": Data("preserve".utf8)])
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertNotNil(try Archive(url: output, accessMode: .read)["empty/"])
    }

    func testNoMatchAndCaseSensitivity() throws {
        let source = try zip([("EN.json", "hello")])
        config.caseSensitive = true
        XCTAssertThrowsError(try Processor.inspect(source, config: config))
        config.caseSensitive = false
        XCTAssertEqual(try Processor.inspect(source, config: config).renamed.count, 1)
    }

    func testRenameChainsUseOriginalNames() throws {
        let source = try zip([("en.json", "english"), ("tr.json", "turkish")])
        config.mappings = ["en": "tr.json", "tr": "final.json"]
        let plan = try Processor.inspect(source, config: config)
        let output = directory.appendingPathComponent("chain.zip")
        try Processor.export(plan, to: output)
        XCTAssertEqual(try contents(output), ["tr.json": Data("english".utf8), "final.json": Data("turkish".utf8)])
    }

    func testCollisionsAndUnsafePathsAreRejected() throws {
        for (index, entries) in [
            [("en.json", "a"), ("english.json", "b")],
            [("en.json", "a"), ("en.txt", "b")],
            [("en.json", "a"), ("english.json/file.txt", "b")],
            [("en.json", "a"), ("../escape", "b")],
            [("en.json", "a"), ("/absolute", "b")],
            [("en.json", "a"), ("EN.json", "b")]
        ].enumerated() {
            let source = try zip(entries, name: "case\(index).zip")
            XCTAssertThrowsError(try Processor.inspect(source, config: config), "Case \(index)")
        }
    }

    func testDuplicateEntriesAndSymlinksAreRejected() throws {
        let duplicate = try zip([("en.json", "a"), ("en.json", "b")])
        XCTAssertThrowsError(try Processor.inspect(duplicate, config: config))
        let source = try zip([("en.json", "a")], name: "symlink.zip")
        do {
            let archive = try Archive(url: source, accessMode: .update)
            let data = Data("../outside".utf8)
            try archive.addEntry(with: "link", type: .symlink, uncompressedSize: Int64(data.count)) { offset, count in data.subdata(in: Int(offset)..<Int(offset) + count) }
        }
        XCTAssertThrowsError(try Processor.inspect(source, config: config))
    }

    func testSourceMutationAndExistingOutputAreRejected() throws {
        let source = try zip([("en.json", "before")])
        let plan = try Processor.inspect(source, config: config)
        XCTAssertThrowsError(try Processor.export(plan, to: source))
        let output = directory.appendingPathComponent("existing.zip")
        try Data("keep".utf8).write(to: output)
        XCTAssertThrowsError(try Processor.export(plan, to: output))
        XCTAssertEqual(try Data(contentsOf: output), Data("keep".utf8))
        try FileManager.default.removeItem(at: source)
        try zip([("en.json", "after")])
        XCTAssertThrowsError(try Processor.export(plan, to: directory.appendingPathComponent("changed.zip")))
    }

    func testCancellationCleansTemporaryFiles() throws {
        let source = try zip([("en.json", String(repeating: "value", count: 20_000))])
        XCTAssertThrowsError(try Processor.inspect(source, config: config, cancelled: { true }))
        let plan = try Processor.inspect(source, config: config)
        let output = directory.appendingPathComponent("cancelled.zip")
        var shouldCancel = false
        XCTAssertThrowsError(try Processor.export(plan, to: output, cancelled: { shouldCancel }, progress: { _ in shouldCancel = true }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: directory.path).contains { $0.hasPrefix(".texterify-") })
    }

    func testCounterAndDateFormats() throws {
        let date = Date(timeIntervalSince1970: 1_789_516_800)
        config.dateFormat = "%Y-%m-%d"
        XCTAssertTrue(config.outputName(date: date).hasPrefix("lang_files_2026-09-"))
        let name = "lang_files_16_09.zip"
        try Data().write(to: directory.appendingPathComponent(name))
        try Data().write(to: directory.appendingPathComponent("lang_files_16_09_1.zip"))
        XCTAssertEqual(Processor.availableDestination(in: directory, name: name).lastPathComponent, "lang_files_16_09_2.zip")
    }

    func testConfigValidationAndMetadataRoundTrip() throws {
        let data = Data("""
        {"_metadata":{"description":"keep"},"language_mappings":{"en":"out.json"},"settings":{"case_sensitive":false}}
        """.utf8)
        let decoded = try Configuration(data: data)
        let roundTrip = try JSONSerialization.jsonObject(with: decoded.encoded()) as! [String: Any]
        XCTAssertEqual((roundTrip["_metadata"] as? [String: String])?["description"], "keep")
        for invalid in [
            "{\"language_mappings\":{}}",
            "{\"language_mappings\":{\"en\":\"../escape\"}}",
            "{\"language_mappings\":{\"en\":\"out\",\"EN\":\"other\"}}",
            "{\"language_mappings\":{\"en\":\"out\",\"tr\":\"OUT\"}}",
            "{\"language_mappings\":{\"en\":\"out\"},\"settings\":{\"backup_original\":true}}",
            "{\"language_mappings\":{\"en\":\"out\"},\"settings\":{\"case_sensitive\":1}}",
            "{\"language_mappings\":{\"en\":\"out\"},\"settings\":{\"typo\":false}}"
        ] { XCTAssertThrowsError(try Configuration(data: Data(invalid.utf8))) }
    }

    func testCorruptAndEncryptedArchivesFailClosed() throws {
        let source = try zip([("en.json", "hello")])
        let data = try Data(contentsOf: source)
        var encrypted = data
        let signature = Data([0x50, 0x4b, 0x01, 0x02])
        let range = try XCTUnwrap(data.range(of: signature))
        encrypted[range.lowerBound + 8] |= 1
        try encrypted.write(to: source)
        XCTAssertThrowsError(try Processor.inspect(source, config: config))
        try data.dropLast(8).write(to: source)
        XCTAssertThrowsError(try Processor.inspect(source, config: config))
        var corrupt = data
        corrupt[range.lowerBound + 16] ^= 0xff // central directory CRC
        try corrupt.write(to: source)
        XCTAssertThrowsError(try Processor.inspect(source, config: config))
    }

    func testRealExportMatchesProvidedOutput() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let source = root.appendingPathComponent("src/Doktar App-16-09-2026-1789557129283.zip")
        let expected = root.appendingPathComponent("src/lang_files_16_09.zip")
        guard FileManager.default.fileExists(atPath: source.path), FileManager.default.fileExists(atPath: expected.path) else {
            throw XCTSkip("Local real-world sample is not present; shared fixtures still run.")
        }
        let config = try Configuration.bundled()
        let plan = try Processor.inspect(source, config: config)
        XCTAssertEqual(plan.renamed.count, 11)
        let output = directory.appendingPathComponent("real.zip")
        try Processor.export(plan, to: output)
        XCTAssertEqual(try contents(output), try contents(expected))
        let repositoryConfig = try Configuration(data: Data(contentsOf: root.appendingPathComponent("config/language_mappings.json")))
        XCTAssertEqual(try config.encoded(), try repositoryConfig.encoded())
    }

    func testSharedPythonSwiftContract() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let fixture = root.appendingPathComponent("tests/fixtures")
        let config = try Configuration(data: Data(contentsOf: fixture.appendingPathComponent("config.json")))
        let plan = try Processor.inspect(fixture.appendingPathComponent("export.zip"), config: config)
        let output = directory.appendingPathComponent("contract.zip")
        try Processor.export(plan, to: output)
        let expected = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: fixture.appendingPathComponent("expected.json")))
        XCTAssertEqual(try contents(output), expected.mapValues { Data($0.utf8) })
    }
}
