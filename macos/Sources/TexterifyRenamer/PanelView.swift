import SwiftUI
import UniformTypeIdentifiers
import RenamerCore

struct PanelView: View {
    @Bindable var model: AppModel
    @State private var preferences = false
    @State private var expanded = false
    @State private var targeted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            if let error = model.error {
                InlineNotice(text: error)
                    .onTapGesture { model.error = nil }
            }
            if preferences {
                QuickSettingsView(model: model)
            } else {
                if let version = model.updates.availableVersion {
                    Button("\(version) sürümü hazır — Güncelle…") { model.checkForUpdates?() }
                        .font(.callout).buttonStyle(.glass).disabled(model.busy)
                }
                content
                footer
            }
        }
        .padding(24).frame(maxWidth: .infinity)
        .buttonBorderShape(.capsule)
        .preferredColorScheme(model.colorScheme)
        .tint(AppPalette.accent)
        .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(targeted ? AppPalette.accent : .clear, lineWidth: 2).allowsHitTesting(false) }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: preferences)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: expanded)
        .onDrop(of: [UTType.fileURL], isTargeted: $targeted) { providers in
            guard providers.count == 1, let provider = providers.first, !model.busy else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { Task { @MainActor in model.receive([url]) } }
            }
            preferences = false
            return true
        }
        .onChange(of: model.busy) { _, busy in if busy { preferences = false } }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if preferences {
                GlassIconButton(title: "Geri", symbol: "chevron.left") { preferences = false }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(preferences ? "Tercihler" : "Renamer").font(.system(size: 19, weight: .semibold, design: .rounded))
                Text(preferences ? "Kayıt ve görünüm" : "TEXTERIFY ZIP").font(.system(size: 9, weight: .medium)).tracking(1.3).foregroundStyle(.secondary)
            }
            Spacer()
            if !preferences {
                GlassIconButton(title: "Tercihler", symbol: "slider.horizontal.3") { preferences = true }
                    .disabled(model.busy)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if model.busy {
            VStack(spacing: 18) {
                ProgressView().controlSize(.regular)
                Text(model.activity).font(.callout).foregroundStyle(.secondary)
                if model.plan != nil { ProgressView(value: model.progress).tint(AppPalette.accent) }
                Button("İptal", action: model.cancel).buttonStyle(.glass)
            }.frame(maxWidth: .infinity).padding(.vertical, 36)
        } else if let saved = model.savedURL {
            VStack(spacing: 16) {
                Image(systemName: "checkmark").font(.system(size: 25, weight: .medium)).foregroundStyle(AppPalette.sage)
                    .frame(width: 64, height: 64).glassEffect(.regular.tint(AppPalette.sage.opacity(0.12)), in: .circle)
                Text("Hazır. Kaydedildi.").font(.system(size: 24, weight: .medium, design: .rounded))
                Text(saved.lastPathComponent).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                Text(saved.deletingLastPathComponent().lastPathComponent).font(.caption).foregroundStyle(.secondary)
                Button("Finder’da göster", action: model.reveal).buttonStyle(.glassProminent).controlSize(.large)
            }.frame(maxWidth: .infinity).padding(.vertical, 14)
        } else if let plan = model.plan {
            ready(plan)
        } else {
            VStack(spacing: 16) {
                Image(systemName: targeted ? "arrow.down" : "doc.zipper")
                    .font(.system(size: 28, weight: .light))
                    .frame(width: 72, height: 72)
                    .foregroundStyle(AppPalette.accent)
                    .glassEffect(.regular.tint(AppPalette.accent.opacity(0.12)).interactive(), in: .rect(cornerRadius: 23))
                VStack(spacing: 7) {
                    Text(targeted ? "Buraya bırak." : "Bırak. Dönüştür. Hazır.")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                    Text("Texterify ZIP’ini bu alana sürükle.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Button("Dosya seç", action: model.chooseInput)
                    .buttonStyle(.glassProminent).controlSize(.large).disabled(model.config == nil)
                    .keyboardShortcut("o", modifiers: .command)
            }.frame(maxWidth: .infinity).padding(.vertical, 22)
        }
    }

    private func ready(_ plan: ProcessingPlan) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "doc.zipper").font(.system(size: 24, weight: .light)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.input.lastPathComponent).font(.callout.weight(.medium)).lineLimit(2).textSelection(.enabled)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(plan.inputBytes), countStyle: .file)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: model.reset) { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                    .buttonStyle(.plain).help("Dosyayı kaldır").accessibilityLabel("Dosyayı kaldır")
            }
            Button { expanded.toggle() } label: {
                HStack {
                    Text("\(plan.renamed.count)").font(.system(size: 32, weight: .light, design: .rounded))
                    Text("dosya eşleşti").font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.caption).foregroundStyle(.secondary)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel("Değişiklikleri göster")
            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(plan.files.filter { !$0.isDirectory }) { file in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(file.source).foregroundStyle(.secondary)
                                Text("↳ \(file.target)").textSelection(.enabled)
                            }.font(.system(size: 11, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.padding(14)
                }.frame(height: 160).background(AppPalette.surface, in: .rect(cornerRadius: 16))
            }
            if !plan.absentLanguages.isEmpty {
                Text("ZIP’te yok: \(plan.absentLanguages.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
            }
            if !plan.preserved.isEmpty {
                Text("\(plan.preserved.count) dosya olduğu gibi korunur.").font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "ÇIKTI")
                Text(model.destination?.lastPathComponent ?? plan.suggestedName).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                Text(model.askEachTime ? "Kayıt yeri sorulacak" : model.folder?.lastPathComponent ?? "İlk indirmede klasörünü seç")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Button(action: model.download) { Label("ZIP’i indir", systemImage: "arrow.down").frame(maxWidth: .infinity) }
                    .buttonStyle(.glassProminent).controlSize(.large).keyboardShortcut(.defaultAction)
                GlassIconButton(title: "Farklı kaydet…", symbol: "folder") { model.saveAs() }
                    .controlSize(.large)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button { model.openSettings?() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                    Text(model.configName)
                    Text("\(model.config?.mappings.count ?? 0)").foregroundStyle(.tertiary)
                    Image(systemName: "arrow.up.right").font(.system(size: 8, weight: .semibold))
                }.font(.caption).foregroundStyle(.secondary)
            }.buttonStyle(.plain).disabled(model.busy).help("Eşleştirmeleri düzenle")
            Spacer()
            if model.savedURL != nil { Button("Yeni dosya", action: model.reset).buttonStyle(.plain).font(.caption) }
            Menu {
                Button("Dosya seç…", action: model.chooseInput).disabled(model.busy)
                Button("Çıkış") { NSApp.terminate(nil) }
            } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Diğer işlemler")
        }.padding(.top, 2)
    }
}
