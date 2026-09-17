import SwiftUI
import RenamerCore

struct QuickSettingsView: View {
    @Bindable var model: AppModel
    @State private var prefix: String
    @State private var dateFormat: String
    @State private var notice: String?
    @State private var failed = false

    init(model: AppModel) {
        self.model = model
        _prefix = State(initialValue: model.config?.prefix ?? "lang_files")
        _dateFormat = State(initialValue: model.config?.dateFormat ?? "%d_%m")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "KAYIT")
                Button { model.chooseFolder() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "folder").font(.title3)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(model.folder?.lastPathComponent ?? "Klasör seç").foregroundStyle(.primary)
                            Text(model.folder?.abbreviatedPath ?? "İlk indirmede de seçebilirsin").font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
                Toggle("Her indirmede kayıt yeri sor", isOn: $model.askEachTime)
                Toggle("Aynı dosya adı varsa bana sor", isOn: $model.askOnConflict)
            }.toggleStyle(.switch).controlSize(.small).font(.callout)
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "DOSYA ADI")
                HStack {
                    TextField("Ön ek", text: $prefix).textFieldStyle(.plain).font(.system(.callout, design: .monospaced))
                        .accessibilityLabel("Çıktı adı ön eki")
                    Picker("Tarih", selection: $dateFormat) {
                        Text("Gün / ay").tag("%d_%m")
                        Text("Yıl / ay / gün").tag("%Y%m%d")
                        Text("Tireli tarih").tag("%Y-%m-%d")
                        Text("Tarih + saat").tag("%Y-%m-%d_%H%M")
                    }.labelsHidden().fixedSize()
                }.padding(12).background(AppPalette.surface, in: .rect(cornerRadius: 12))
                HStack {
                    Text(preview).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
                    Spacer(minLength: 4)
                    Button("Uygula", action: saveNaming).buttonStyle(.glass).controlSize(.small)
                        .disabled(model.config == nil || (prefix == model.config?.prefix && dateFormat == model.config?.dateFormat))
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "GÖRÜNÜM")
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        themeButton("Sistem", symbol: "circle.lefthalf.filled", value: "system")
                        themeButton("Açık", symbol: "sun.max", value: "light")
                        themeButton("Koyu", symbol: "moon", value: "dark")
                    }
                }
            }
            if let notice { InlineNotice(text: notice, isError: failed) }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: "GÜNCELLEMELER")
                    Spacer()
                    Text("v\(model.updates.version)").font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Toggle("Güncellemeleri otomatik denetle", isOn: Binding(
                    get: { model.updates.automaticallyChecks }, set: { model.updates.automaticallyChecks = $0 }))
                    .toggleStyle(.switch).controlSize(.small).font(.callout)
                Button(model.updates.availableVersion.map { "\($0) sürümünü yükle…" } ?? "Güncellemeleri denetle…") {
                    model.checkForUpdates?()
                }.buttonStyle(.glass).controlSize(.small).disabled(!model.updates.canCheck || model.busy)
                if let error = model.updates.startupError { InlineNotice(text: error, isError: true) }
            }
            Button { model.openSettings?() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Eşleştirmeler").font(.callout.weight(.medium))
                        Text("\(model.configName) · \(model.config?.mappings.count ?? 0) dil").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                }.padding(13)
            }.buttonStyle(.plain).glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        }
        .onChange(of: model.askEachTime) { _, _ in model.savePreferences() }
        .onChange(of: model.askOnConflict) { _, _ in model.savePreferences() }
        .onChange(of: model.appearance) { _, _ in model.savePreferences() }
    }

    private func themeButton(_ title: String, symbol: String, value: String) -> some View {
        Button { model.appearance = value } label: {
            Label(title, systemImage: symbol).font(.caption).frame(maxWidth: .infinity).padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(model.appearance == value ? AppPalette.accent.opacity(0.2) : .clear).interactive(), in: .capsule)
        .accessibilityAddTraits(model.appearance == value ? .isSelected : [])
    }

    private var preview: String {
        guard var config = model.config else { return "—" }
        config.prefix = prefix; config.dateFormat = dateFormat
        return config.outputName()
    }
    private func saveNaming() {
        guard var config = model.config else { return }
        config.prefix = prefix; config.dateFormat = dateFormat
        do { try model.saveConfig(config, name: model.configName); notice = "Dosya adı güncellendi."; failed = false }
        catch { notice = model.readable(error); failed = true }
    }
}

private extension URL {
    var abbreviatedPath: String { (path as NSString).abbreviatingWithTildeInPath }
}
