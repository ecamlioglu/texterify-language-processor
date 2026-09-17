import Foundation

public struct RenamerError: LocalizedError, Equatable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

/// Keeps the original JSON document so annotations survive an import/export cycle.
public struct Configuration: Sendable {
    public var mappings: [String: String]
    public var caseSensitive: Bool
    public var prefix: String
    public var dateFormat: String
    private var document: Data

    public static let dateFormats = ["%d_%m", "%Y%m%d", "%Y-%m-%d", "%Y-%m-%d_%H%M"]

    public init(data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mappings = json["language_mappings"] as? [String: String] else {
            throw RenamerError("Config içinde language_mappings alanı bulunmalı; dil ve hedef adları metin olmalı.")
        }
        if let settings = json["settings"], !(settings is [String: Any]) {
            throw RenamerError("settings bir JSON nesnesi olmalı.")
        }
        let settings = json["settings"] as? [String: Any] ?? [:]
        let known = Set(["case_sensitive", "preserve_extensions", "backup_original", "output_format"])
        let unknown = Set(settings.keys).subtracting(known)
        guard unknown.isEmpty else { throw RenamerError("Desteklenmeyen ayar: \(unknown.sorted().joined(separator: ", "))") }
        for key in ["case_sensitive", "preserve_extensions", "backup_original"] {
            if let value = settings[key] {
                guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
                    throw RenamerError("\(key) true veya false olmalı.")
                }
            }
        }
        guard settings["preserve_extensions"] as? Bool != true, settings["backup_original"] as? Bool != true else {
            throw RenamerError("preserve_extensions ve backup_original bu sürümde desteklenmiyor. Kaynak ZIP her zaman korunur.")
        }
        if let format = settings["output_format"], !(format is [String: Any]) {
            throw RenamerError("output_format bir JSON nesnesi olmalı.")
        }
        let format = settings["output_format"] as? [String: Any] ?? [:]
        guard Set(format.keys).subtracting(["date_format", "base_filename", "extension"]).isEmpty else {
            throw RenamerError("output_format içinde desteklenmeyen ayar var.")
        }
        for (key, value) in format where !(value is String) { throw RenamerError("\(key) metin olmalı.") }
        guard (format["extension"] as? String ?? ".zip") == ".zip" else { throw RenamerError("Çıktı uzantısı .zip olmalı.") }
        self.mappings = mappings
        self.caseSensitive = settings["case_sensitive"] as? Bool ?? false
        self.prefix = format["base_filename"] as? String ?? "lang_files"
        self.dateFormat = format["date_format"] as? String ?? "%d_%m"
        self.document = data
        try validate()
    }

    public static func bundled() throws -> Configuration {
        guard let url = Bundle.module.url(forResource: "default-config", withExtension: "json") else {
            throw RenamerError("Varsayılan config uygulama paketinde bulunamadı.")
        }
        return try Configuration(data: Data(contentsOf: url))
    }

    public func validate() throws {
        guard !mappings.isEmpty else { throw RenamerError("En az bir dil eşleştirmesi ekle.") }
        var sources = Set<String>(), targets = Set<String>()
        for (source, target) in mappings {
            guard Self.safeName(source), Self.safeName(target) else {
                throw RenamerError("Geçersiz eşleştirme: \(source) → \(target). Klasör yolu yerine dosya adı kullan.")
            }
            let key = caseSensitive ? source.precomposedStringWithCanonicalMapping : Self.canonical(source)
            guard sources.insert(key).inserted else { throw RenamerError("Dil kodu birden fazla tanımlı: \(source)") }
            guard targets.insert(Self.canonical(target)).inserted else { throw RenamerError("Hedef dosya adı birden fazla kullanılıyor: \(target)") }
        }
        guard Self.safeName(prefix) else { throw RenamerError("Geçerli bir çıktı adı ön eki gir.") }
        guard Self.dateFormats.contains(dateFormat) else { throw RenamerError("Desteklenmeyen tarih biçimi: \(dateFormat)") }
    }

    public func encoded() throws -> Data {
        try validate()
        var json = try JSONSerialization.jsonObject(with: document) as? [String: Any] ?? [:]
        json["language_mappings"] = mappings
        json["settings"] = ["case_sensitive": caseSensitive, "preserve_extensions": false, "backup_original": false,
                            "output_format": ["base_filename": prefix, "date_format": dateFormat, "extension": ".zip"]] as [String: Any]
        return try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }

    public func target(for filename: String) -> String? {
        // Match pathlib's final-extension stem, including dotfiles.
        let stem: String
        if let dot = filename.lastIndex(of: "."), dot != filename.startIndex, dot != filename.index(before: filename.endIndex) {
            stem = String(filename[..<dot])
        } else { stem = filename }
        return mappings.first { caseSensitive ? $0.key == stem : Self.canonical($0.key) == Self.canonical(stem) }?.value
    }

    public func outputName(date: Date = Date()) -> String {
        let formats = ["%d_%m": "dd_MM", "%Y%m%d": "yyyyMMdd", "%Y-%m-%d": "yyyy-MM-dd", "%Y-%m-%d_%H%M": "yyyy-MM-dd_HHmm"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = formats[dateFormat] ?? "dd_MM"
        return "\(prefix)_\(formatter.string(from: date)).zip"
    }

    static func canonical(_ value: String) -> String { value.precomposedStringWithCanonicalMapping.lowercased() }
    static func safeName(_ value: String) -> Bool {
        !value.isEmpty && value == value.trimmingCharacters(in: .whitespacesAndNewlines) && value != "." && value != ".." &&
        !value.contains(where: { $0 == "/" || $0 == "\\" || $0 == ":" || $0.isNewline }) &&
        !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) && value.utf8.count <= 240
    }
}

import CoreFoundation
