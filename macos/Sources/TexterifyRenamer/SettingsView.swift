import SwiftUI
import AppKit
import UniformTypeIdentifiers
import RenamerCore

private struct MappingRow: Identifiable {
    let id = UUID()
    var source: String
    var target: String
}

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var draft: Configuration?
    @State private var rows: [MappingRow]
    @State private var name: String
    @State private var caseSensitive: Bool
    @State private var error: String?
    @State private var message: String?
    @State private var showJSON = false
    @State private var query = ""
    @State private var importedDraft = false
    @Environment(\.appearsActive) private var appearsActive

    init(model: AppModel) {
        self.model = model
        let config = model.config
        _draft = State(initialValue: config)
        _rows = State(initialValue: (config?.mappings ?? [:]).sorted { $0.key < $1.key }.map { MappingRow(source: $0.key, target: $0.value) })
        _name = State(initialValue: model.configName)
        _caseSensitive = State(initialValue: config?.caseSensitive ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.horizontal, 32).padding(.top, 22).padding(.bottom, 24)
            toolbar.padding(.horizontal, 32).padding(.bottom, 20)
            if let error { InlineNotice(text: error).padding(.horizontal, 32).padding(.bottom, 12) }
            if let message { InlineNotice(text: message, isError: false).padding(.horizontal, 32).padding(.bottom, 12) }
            if showJSON { jsonView } else { mappingList }
            footer.padding(.horizontal, 32).padding(.vertical, 20)
        }
        .frame(minWidth: 660, idealWidth: 780, minHeight: 530, idealHeight: 670)
        .buttonBorderShape(.capsule)
        .preferredColorScheme(model.colorScheme)
        .tint(AppPalette.accent)
        .background { SoftBackdrop().ignoresSafeArea() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: save) { Label("Kaydet", systemImage: "checkmark") }
                    .buttonStyle(.glassProminent).tint(AppPalette.accent)
                    .keyboardShortcut("s", modifiers: .command).disabled(model.busy || draft == nil)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Eyebrow(text: "AKTİF CONFIG")
                HStack(spacing: 6) {
                    TextField("Config adı", text: $name).textFieldStyle(.plain).fixedSize().accessibilityLabel("Config adı")
                    Text("· \(rows.count) dil").foregroundStyle(.tertiary)
                }.font(.system(size: 20, weight: .medium, design: .rounded)).foregroundStyle(.primary)
            }
            Spacer()
        }.opacity(appearsActive ? 1 : 0.7)
    }

    private var toolbar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Dil veya dosya ara", text: $query).textFieldStyle(.plain)
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain).accessibilityLabel("Aramayı temizle")
                    }
                }.padding(.horizontal, 14).frame(height: 38).glassEffect(.regular, in: .capsule)
                    .disabled(showJSON)
                HStack(spacing: 2) {
                    Button { showJSON = false } label: { Image(systemName: "list.bullet").frame(width: 30, height: 30) }
                        .foregroundStyle(showJSON ? .secondary : .primary).accessibilityLabel("Eşleştirme listesi")
                    Button { showJSON = true } label: { Image(systemName: "curlybraces").frame(width: 30, height: 30) }
                        .foregroundStyle(showJSON ? .primary : .secondary).accessibilityLabel("JSON önizleme")
                }.buttonStyle(.plain).padding(4).glassEffect(.regular.interactive(), in: .capsule)
                GlassIconButton(title: "Eşleştirme ekle", symbol: "plus") {
                    query = ""; showJSON = false; rows.insert(MappingRow(source: "", target: ""), at: 0)
                }.controlSize(.large)
            }
        }
    }

    private var mappingList: some View {
        VStack(spacing: 0) {
            HStack {
                Eyebrow(text: "KAYNAK DİL").frame(width: 112, alignment: .leading)
                Eyebrow(text: "ÇIKTI DOSYASI")
                Spacer()
            }.padding(.horizontal, 18).padding(.bottom, 12)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach($rows) { $row in
                        if matches(row) {
                            HStack(spacing: 16) {
                                TextField("en", text: $row.source).font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppPalette.accent).frame(width: 70).accessibilityLabel("Dil kodu")
                                Image(systemName: "arrow.right").font(.system(size: 10)).foregroundStyle(.tertiary)
                                TextField("Hedef dosya adı", text: $row.target).font(.system(size: 12, design: .monospaced))
                                    .accessibilityLabel("Hedef dosya adı")
                                Button { rows.removeAll { $0.id == row.id } } label: { Image(systemName: "minus.circle").foregroundStyle(.tertiary) }
                                    .buttonStyle(.plain).help("Eşleştirmeyi sil").accessibilityLabel("\(row.source) eşleştirmesini sil")
                            }.textFieldStyle(.plain).padding(.horizontal, 18).frame(height: 44)
                            Divider().opacity(0.45).padding(.horizontal, 18)
                        }
                    }
                    if !rows.contains(where: matches) {
                        ContentUnavailableView.search(text: query).padding(.vertical, 30)
                    }
                }.padding(.vertical, 5)
            }
            .background(AppPalette.surface, in: .rect(cornerRadius: 18))
        }.padding(.horizontal, 32)
    }

    private var jsonView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "JSON ÖNİZLEME")
                Spacer()
                Button("Kopyala") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(jsonText, forType: .string) }
                    .buttonStyle(.glass).controlSize(.small)
            }
            ScrollView([.vertical, .horizontal]) {
                Text(jsonText).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(AppPalette.surface, in: .rect(cornerRadius: 18))
        }.padding(.horizontal, 32)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Toggle("Büyük/küçük harf duyarlı", isOn: $caseSensitive).toggleStyle(.switch).controlSize(.mini).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("Geri al") { load(model.config); error = nil; message = nil }.buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            Menu {
                Button("JSON içe aktar…", action: importConfig)
                Button("JSON dışa aktar…", action: exportConfig).disabled(draft == nil)
                Divider()
                Button("Varsayılanı yükle") {
                    perform { load(try Configuration.bundled()); importedDraft = true; name = "Doktar"; message = "Varsayılan config hazır. Uygulamak için Kaydet’e bas." }
                }
            } label: { Label("Config", systemImage: "ellipsis") }.menuStyle(.borderlessButton).fixedSize().font(.caption)
        }
    }

    private var jsonText: String {
        do { return String(decoding: try configuration().encoded(), as: UTF8.self) }
        catch { return error.localizedDescription }
    }
    private func matches(_ row: MappingRow) -> Bool {
        query.isEmpty || row.source.localizedCaseInsensitiveContains(query) || row.target.localizedCaseInsensitiveContains(query)
    }

    private func configuration() throws -> Configuration {
        guard var draft else { throw RenamerError("Önce geçerli bir config içe aktar veya varsayılanı yükle.") }
        var mappings = [String: String]()
        for row in rows {
            guard mappings[row.source] == nil else { throw RenamerError("Dil kodu birden fazla tanımlı: \(row.source)") }
            mappings[row.source] = row.target
        }
        draft.mappings = mappings; draft.caseSensitive = caseSensitive
        if !importedDraft, let active = model.config { draft.prefix = active.prefix; draft.dateFormat = active.dateFormat }
        try draft.validate()
        return draft
    }

    private func load(_ config: Configuration?) {
        draft = config
        rows = (config?.mappings ?? [:]).sorted { $0.key < $1.key }.map { MappingRow(source: $0.key, target: $0.value) }
        name = model.configName; caseSensitive = config?.caseSensitive ?? false; importedDraft = false
    }
    private func perform(_ work: () throws -> Void) {
        error = nil; message = nil
        do { try work() } catch { self.error = model.readable(error) }
    }
    private func save() {
        perform { let config = try configuration(); try model.saveConfig(config, name: name); draft = config; importedDraft = false; message = "Config kaydedildi." }
    }
    private func importConfig() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.json]; panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                perform { load(try Configuration(data: Data(contentsOf: url))); importedDraft = true; name = url.deletingPathExtension().lastPathComponent; message = "Config taslağa yüklendi. Uygulamak için Kaydet’e bas." }
            }
        }
    }
    private func exportConfig() {
        perform {
            let data = try configuration().encoded()
            let panel = NSSavePanel(); panel.allowedContentTypes = [.json]; panel.nameFieldStringValue = "language_mappings.json"
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    perform { try data.write(to: url, options: .atomic); message = "Config dışa aktarıldı." }
                }
            }
        }
    }
}
