import Foundation
import CryptoKit
import ZIPFoundation
import Darwin

public struct PlannedFile: Identifiable, Sendable {
    public var id: String { source }
    public let source: String
    public let target: String
    public let size: UInt64
    public let isDirectory: Bool
    public var renamed: Bool { source != target }
}

public struct ProcessingPlan: Sendable {
    public let input: URL
    public let files: [PlannedFile]
    public let suggestedName: String
    public let inputBytes: Int
    public let absentLanguages: [String]
    fileprivate let digest: SHA256.Digest
    public var renamed: [PlannedFile] { files.filter { !$0.isDirectory && $0.renamed } }
    public var preserved: [PlannedFile] { files.filter { !$0.isDirectory && !$0.renamed } }
}

public enum Processor {
    public static let maxInputBytes = 100 * 1024 * 1024
    public static let maxExpandedBytes: UInt64 = 500 * 1024 * 1024
    public static let maxEntries = 10_000

    public static func inspect(_ input: URL, config: Configuration,
                               cancelled: () -> Bool = { false }) throws -> ProcessingPlan {
        try config.validate()
        guard input.pathExtension.lowercased() == "zip" else { throw RenamerError("Texterify’dan indirdiğin .zip dosyasını seç.") }
        let data = try snapshot(input)
        let archive = try validatedArchive(data)
        var files = [PlannedFile](), sources = Set<String>(), targets = Set<String>(), seenLanguages = Set<String>()
        var declared: UInt64 = 0
        for entry in archive {
            try checkCancellation(cancelled)
            guard entry.type != .symlink else { throw RenamerError("Arşiv sembolik bağlantı içeriyor: \(entry.path)") }
            try validatePath(entry.path)
            let directory = entry.type == .directory
            let source = entry.path
            let normalized = Configuration.canonical(source.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            guard sources.insert(normalized).inserted else { throw RenamerError("Arşivde yinelenen dosya yolu: \(source)") }
            guard entry.uncompressedSize <= maxExpandedBytes - declared else { throw RenamerError("Arşivin açılmış boyutu 500 MB sınırını aşıyor.") }
            declared += entry.uncompressedSize
            var target = source
            if !directory {
                let name = (source as NSString).lastPathComponent
                if let mapped = config.target(for: name) {
                    let parent = (source as NSString).deletingLastPathComponent
                    target = parent.isEmpty ? mapped : parent + "/" + mapped
                    for (language, mappedName) in config.mappings where mappedName == mapped { seenLanguages.insert(language) }
                }
                try read(entry, in: archive, cancelled: cancelled) { _ in }
            }
            let targetKey = Configuration.canonical(target.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            guard targets.insert(targetKey).inserted else { throw RenamerError("Dosyalar aynı hedefe gidiyor: \(target)") }
            files.append(PlannedFile(source: source, target: target, size: entry.uncompressedSize, isDirectory: directory))
        }
        let fileTargets = Set(files.filter { !$0.isDirectory }.map { Configuration.canonical($0.target) })
        for file in files {
            var parent = (file.target.trimmingCharacters(in: CharacterSet(charactersIn: "/")) as NSString).deletingLastPathComponent
            while !parent.isEmpty {
                guard !fileTargets.contains(Configuration.canonical(parent)) else { throw RenamerError("Dosya ve klasör hedefleri çakışıyor: \(parent)") }
                parent = (parent as NSString).deletingLastPathComponent
            }
        }
        guard files.contains(where: { !$0.isDirectory && $0.renamed }) else {
            throw RenamerError("Yeniden adlandırılacak dosya bulunamadı. ZIP’i ve dil eşleştirmelerini kontrol et.")
        }
        return ProcessingPlan(input: input, files: files, suggestedName: config.outputName(), inputBytes: data.count,
                              absentLanguages: Set(config.mappings.keys).subtracting(seenLanguages).sorted(), digest: SHA256.hash(data: data))
    }

    /// Publishes with an exclusive hard link on the destination volume: an existing file is never replaced.
    public static func export(_ plan: ProcessingPlan, to destination: URL,
                              cancelled: () -> Bool = { false }, progress: (Double) -> Void = { _ in }) throws {
        guard destination.pathExtension.lowercased() == "zip" else { throw RenamerError("Çıktı dosyası .zip uzantılı olmalı.") }
        guard plan.input.resolvingSymlinksInPath().standardizedFileURL != destination.resolvingSymlinksInPath().standardizedFileURL else {
            throw RenamerError("Kaynak ZIP’in üzerine yazılamaz.")
        }
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw RenamerError("Bu dosya zaten var. Başka bir ad seç veya numara ekle.") }
        let data = try snapshot(plan.input)
        guard SHA256.hash(data: data) == plan.digest else { throw RenamerError("Girdi dosyası önizlemeden sonra değişti. Dosyayı yeniden seç.") }
        let archive = try validatedArchive(data)
        // The system supplies a temporary location on the destination volume. A
        // save-panel grant may cover only the file, not arbitrary sibling folders.
        let stage = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                               appropriateFor: destination, create: true)
        defer { try? FileManager.default.removeItem(at: stage) }
        let temporaryZIP = stage.appendingPathComponent("result.zip")
        try writeArchive(archive, plan: plan, output: temporaryZIP, stage: stage, cancelled: cancelled, progress: progress)
        try checkCancellation(cancelled)
        let result = try Archive(url: temporaryZIP, accessMode: .read)
        guard Array(result).count == plan.files.count else { throw RenamerError("Çıktı doğrulanamadı; dosya kaydedilmedi.") }
        for (entry, expected) in zip(result, plan.files) {
            guard entry.path == expected.target, entry.uncompressedSize == expected.size else { throw RenamerError("Çıktı dosyaları beklenen sonuçla eşleşmedi.") }
            if !expected.isDirectory { try read(entry, in: result, cancelled: cancelled) { _ in } }
        }
        let handle = try FileHandle(forWritingTo: temporaryZIP)
        try handle.synchronize()
        try handle.close()
        try checkCancellation(cancelled)
        let published = temporaryZIP.withUnsafeFileSystemRepresentation { from in
            destination.withUnsafeFileSystemRepresentation { to in Darwin.link(from!, to!) }
        }
        guard published == 0 else {
            if errno == EEXIST { throw RenamerError("Bu ad kaydetme sırasında kullanıldı. Yeni bir ad seçip tekrar dene.") }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        progress(1)
    }

    public static func availableDestination(in folder: URL, name: String) -> URL {
        let original = folder.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: original.path) { return original }
        let stem = original.deletingPathExtension().lastPathComponent
        var counter = 1
        while FileManager.default.fileExists(atPath: folder.appendingPathComponent("\(stem)_\(counter).zip").path) { counter += 1 }
        return folder.appendingPathComponent("\(stem)_\(counter).zip")
    }

    private static func writeArchive(_ source: Archive, plan: ProcessingPlan, output: URL, stage: URL,
                                     cancelled: () -> Bool, progress: (Double) -> Void) throws {
        let archive = try Archive(url: output, accessMode: .create)
        let entries = Array(source)
        for (index, file) in plan.files.enumerated() {
            try checkCancellation(cancelled)
            let entry = entries[index]
            if file.isDirectory {
                try archive.addEntry(with: file.target, type: .directory, uncompressedSize: Int64(0)) { _, _ in Data() }
            } else {
                let spool = stage.appendingPathComponent("entry")
                FileManager.default.createFile(atPath: spool.path, contents: nil)
                let writer = try FileHandle(forWritingTo: spool)
                do {
                    try read(entry, in: source, cancelled: cancelled) { try writer.write(contentsOf: $0) }
                    try writer.close()
                } catch { try? writer.close(); throw error }
                let reader = try FileHandle(forReadingFrom: spool)
                do {
                    try archive.addEntry(with: file.target, type: .file, uncompressedSize: Int64(file.size), compressionMethod: .deflate) { offset, count in
                        try checkCancellation(cancelled)
                        try reader.seek(toOffset: UInt64(offset))
                        return try reader.read(upToCount: count) ?? Data()
                    }
                    try reader.close()
                } catch { try? reader.close(); throw error }
                try FileManager.default.removeItem(at: spool)
            }
            progress(Double(index + 1) / Double(plan.files.count) * 0.9)
        }
    }

    private static func read(_ entry: Entry, in archive: Archive, cancelled: () -> Bool, consume: (Data) throws -> Void) throws {
        var size: UInt64 = 0
        let crc = try archive.extract(entry) { chunk in
            try checkCancellation(cancelled)
            size += UInt64(chunk.count)
            guard size <= entry.uncompressedSize, size <= maxExpandedBytes else { throw RenamerError("Arşivde bildirilen dosya boyutu geçersiz.") }
            try consume(chunk)
        }
        guard crc == entry.checksum, size == entry.uncompressedSize else { throw RenamerError("ZIP içindeki dosya bozuk: \(entry.path)") }
    }

    private static func snapshot(_ url: URL) throws -> Data {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else { throw RenamerError("Bir ZIP dosyası seç.") }
        guard (values.fileSize ?? 0) <= maxInputBytes else { throw RenamerError("ZIP dosyası 100 MB sınırını aşıyor.") }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: maxInputBytes + 1) ?? Data()
        guard data.count <= maxInputBytes else { throw RenamerError("ZIP dosyası 100 MB sınırını aşıyor.") }
        return data
    }

    private static func validatePath(_ path: String) throws {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        let checked = path.hasSuffix("/") ? components.dropLast() : components[...]
        guard !checked.isEmpty, checked.allSatisfy({ Configuration.safeName(String($0)) }) else {
            throw RenamerError("Arşivde güvenli olmayan dosya yolu: \(path)")
        }
    }

    /// ZIPFoundation skips encrypted/invalid entries in its iterator. Validate the directory
    /// first so a partially readable ZIP cannot silently produce a partial export.
    private static func validatedArchive(_ data: Data) throws -> Archive {
        func number(_ offset: Int, _ size: Int) throws -> Int {
            guard offset >= 0, offset + size <= data.count else { throw RenamerError("ZIP yapısı bozuk.") }
            return (0..<size).reduce(0) { $0 | Int(data[offset + $1]) << ($1 * 8) }
        }
        guard data.count >= 22 else { throw RenamerError("Geçerli bir ZIP dosyası değil.") }
        var end: Int?
        for offset in stride(from: data.count - 22, through: max(0, data.count - 65557), by: -1) {
            if try number(offset, 4) == 0x06054b50, offset + 22 + (try number(offset + 20, 2)) == data.count { end = offset; break }
        }
        guard let end else { throw RenamerError("ZIP dizini bulunamadı; dosya bozuk olabilir.") }
        let count = try number(end + 10, 2)
        guard try number(end + 4, 2) == 0, try number(end + 6, 2) == 0, try number(end + 8, 2) == count,
              count > 0, count <= maxEntries else { throw RenamerError("Boş, çok parçalı, ZIP64 veya 10.000’den fazla giriş içeren arşiv desteklenmiyor.") }
        let start = try number(end + 16, 4), length = try number(end + 12, 4)
        guard start + length == end else { throw RenamerError("ZIP dizini geçersiz; ZIP64 arşivler bu sürümde desteklenmiyor.") }
        var position = start
        for _ in 0..<count {
            guard try number(position, 4) == 0x02014b50 else { throw RenamerError("ZIP dizini bozuk.") }
            guard try number(position + 8, 2) & 1 == 0 else { throw RenamerError("Şifreli ZIP dosyaları desteklenmiyor.") }
            let extra = try number(position + 28, 2) + number(position + 30, 2) + number(position + 32, 2)
            position += 46 + extra
            guard position <= end else { throw RenamerError("ZIP dizini eksik.") }
        }
        guard position == end else { throw RenamerError("ZIP dizini boyutu geçersiz.") }
        let archive = try Archive(data: data, accessMode: .read)
        guard Array(archive).count == count else { throw RenamerError("ZIP girişlerinin tümü okunamadı; dosya bozuk veya desteklenmeyen biçimde.") }
        return archive
    }

    private static func checkCancellation(_ cancelled: () -> Bool) throws {
        if cancelled() { throw CancellationError() }
    }
}
