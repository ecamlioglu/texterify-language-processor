import AppKit
import SwiftUI
import Observation
import UniformTypeIdentifiers
import RenamerCore

final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var value: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
}

@MainActor
@Observable
final class AppModel {
    let updates = AppUpdater()
    var checkForUpdates: (() -> Void)?
    var config: Configuration?
    var plan: ProcessingPlan?
    var savedURL: URL?
    var error: String?
    var busy = false
    var activity = ""
    var progress: Double = 0
    var folder: URL?
    var askEachTime: Bool
    var askOnConflict: Bool
    var colorScheme: ColorScheme = .light
    var appearance: String
    var configName: String
    var openSettings: (() -> Void)?
    var showPanel: (() -> Void)?
    var beforeDialog: (() -> Void)?
    var appearanceChanged: (() -> Void)?
    private var input: URL?
    private var inputScoped = false
    private var folderScoped = false
    private var cancellation = CancellationFlag()
    private let defaults = UserDefaults.standard
    private let configURL: URL

    init() {
        askEachTime = defaults.bool(forKey: "askEachTime")
        askOnConflict = defaults.bool(forKey: "askOnConflict")
        appearance = defaults.string(forKey: "appearance") ?? "system"
        configName = defaults.string(forKey: "configName") ?? "Doktar"
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TexterifyRenamer", isDirectory: true)
        configURL = directory.appendingPathComponent("config.json")
        do {
            if FileManager.default.fileExists(atPath: configURL.path) {
                config = try Configuration(data: Data(contentsOf: configURL))
            } else { config = try Configuration.bundled() }
        } catch { self.error = "Config açılamadı: \(error.localizedDescription) Ayarlardan geçerli bir config içe aktar." }
        if let bookmark = defaults.data(forKey: "outputBookmark") {
            do {
                var stale = false
                let url = try URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale)
                folderScoped = url.startAccessingSecurityScopedResource()
                folder = url
                if stale { defaults.set(try url.bookmarkData(options: .withSecurityScope), forKey: "outputBookmark") }
            } catch { self.error = "Kayıt klasörüne erişim yenilenmeli. Ayarlardan klasörü yeniden seç." }
        }
    }

    var destination: URL? {
        guard let plan, let folder else { return nil }
        return Processor.availableDestination(in: folder, name: plan.suggestedName)
    }

    func receive(_ urls: [URL]) {
        guard !busy else { error = "Bir işlem devam ediyor. Bitmesini bekle veya iptal et."; showPanel?(); return }
        guard urls.count == 1, let url = urls.first, url.isFileURL else {
            error = "Her seferinde tek bir yerel ZIP dosyası bırak."; showPanel?(); return
        }
        if inputScoped { input?.stopAccessingSecurityScopedResource() }
        input = url
        inputScoped = url.startAccessingSecurityScopedResource()
        showPanel?()
        inspect()
    }

    func inspect() {
        guard let input, let config, !busy else { return }
        plan = nil; savedURL = nil; error = nil; busy = true; activity = "ZIP inceleniyor…"
        let flag = CancellationFlag(); cancellation = flag
        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try Processor.inspect(input, config: config, cancelled: { flag.value })
                }.value
                if !flag.value { plan = result }
            } catch is CancellationError { }
            catch { self.error = readable(error) }
            busy = false
        }
    }

    func chooseInput() {
        guard !busy else { return }
        beforeDialog?(); NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip]; panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false; panel.message = "Texterify’dan indirdiğin ZIP dosyasını seç."
        panel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK { self.receive(panel.urls) } else { self.showPanel?() }
        }
    }

    func chooseFolder(then continuation: (() -> Void)? = nil) {
        beforeDialog?(); NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = true
        panel.prompt = "Klasörü seç"; panel.message = "Dönüştürülen ZIP’lerin kaydedileceği klasörü seç."
        panel.directoryURL = folder ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        panel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK, let selected = panel.url {
                let scoped = selected.startAccessingSecurityScopedResource()
                do {
                    let bookmark = try selected.bookmarkData(options: .withSecurityScope)
                    if self.folderScoped { self.folder?.stopAccessingSecurityScopedResource() }
                    self.folder = selected; self.folderScoped = scoped
                    self.defaults.set(bookmark, forKey: "outputBookmark")
                    self.error = nil
                    self.showPanel?(); continuation?()
                } catch {
                    if scoped { selected.stopAccessingSecurityScopedResource() }
                    self.error = self.readable(error); self.showPanel?()
                }
            } else { self.showPanel?() }
        }
    }

    func download() {
        guard let plan, !busy else { return }
        if askEachTime { saveAs(); return }
        guard let folder else { chooseFolder { [weak self] in self?.download() }; return }
        let original = folder.appendingPathComponent(plan.suggestedName)
        if askOnConflict && FileManager.default.fileExists(atPath: original.path) { saveAs(); return }
        export(to: Processor.availableDestination(in: folder, name: plan.suggestedName))
    }

    func saveAs() {
        guard let plan, !busy else { return }
        beforeDialog?(); NSApp.activate(ignoringOtherApps: true)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]; panel.canCreateDirectories = true
        panel.nameFieldStringValue = destination?.lastPathComponent ?? plan.suggestedName
        panel.directoryURL = folder ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        panel.message = "Yeni bir dosya adı seç. Mevcut dosyalar korunur."
        panel.begin { [weak self] response in
            guard let self else { return }
            self.showPanel?()
            if response == .OK, let url = panel.url { self.export(to: url) }
        }
    }

    private func export(to url: URL) {
        guard let plan, !busy else { return }
        busy = true; activity = "ZIP hazırlanıyor…"; error = nil; progress = 0
        let flag = CancellationFlag(); cancellation = flag
        let scoped = url.startAccessingSecurityScopedResource()
        Task {
            defer { if scoped { url.stopAccessingSecurityScopedResource() }; busy = false }
            do {
                try await Task.detached(priority: .userInitiated) {
                    try Processor.export(plan, to: url, cancelled: { flag.value }) { fraction in
                        Task { @MainActor in self.progress = fraction }
                    }
                }.value
                savedURL = url
            } catch is CancellationError { }
            catch { self.error = readable(error) }
        }
    }

    func reset() {
        guard !busy else { return }
        if inputScoped { input?.stopAccessingSecurityScopedResource() }
        inputScoped = false; input = nil; plan = nil; savedURL = nil; error = nil
    }
    func cancel() { cancellation.cancel(); activity = "İptal ediliyor…" }
    func reveal() { if let savedURL { NSWorkspace.shared.activateFileViewerSelecting([savedURL]) } }

    func saveConfig(_ draft: Configuration, name: String) throws {
        guard !busy else { throw RenamerError("Config’i kaydetmeden önce devam eden işlemi bitir veya iptal et.") }
        let data = try draft.encoded()
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: configURL, options: .atomic)
        config = draft; configName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Config" : name
        defaults.set(configName, forKey: "configName")
        error = nil; inspect()
    }

    func savePreferences() {
        defaults.set(askEachTime, forKey: "askEachTime")
        defaults.set(askOnConflict, forKey: "askOnConflict")
        defaults.set(appearance, forKey: "appearance")
        appearanceChanged?()
    }

    func readable(_ error: Error) -> String {
        if error is RenamerError { return error.localizedDescription }
        let cocoa = error as NSError
        if cocoa.domain == NSCocoaErrorDomain && [NSFileReadNoPermissionError, NSFileWriteNoPermissionError].contains(cocoa.code) {
            return "Dosyaya veya kayıt klasörüne erişilemiyor. Dosyayı/klasörü yeniden seç."
        }
        return "İşlem tamamlanamadı: \(error.localizedDescription)"
    }
}
