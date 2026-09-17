import SwiftUI
import AppKit

enum AppPalette {
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.73, green: 0.67, blue: 0.94, alpha: 1)
            : NSColor(srgbRed: 0.45, green: 0.35, blue: 0.68, alpha: 1)
    })
    static let sage = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.57, green: 0.78, blue: 0.68, alpha: 1)
            : NSColor(srgbRed: 0.25, green: 0.48, blue: 0.39, alpha: 1)
    })
    static let surface = Color(nsColor: .textBackgroundColor).opacity(0.48)
}

struct SoftBackdrop: View {
    var panel = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var canvas: Color {
        scheme == .dark ? Color(red: 0.14, green: 0.145, blue: 0.19) : Color(red: 0.965, green: 0.96, blue: 0.985)
    }
    var body: some View {
        ZStack {
            if panel { PanelGlass() } else { WindowMaterial() }
            canvas.opacity(reduceTransparency ? 1 : panel ? 0.18 : 0.8)
            LinearGradient(colors: [AppPalette.accent.opacity(scheme == .dark ? 0.13 : 0.085), .clear, AppPalette.sage.opacity(0.075)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }.allowsHitTesting(false)
    }
}

/// Native system materials respect appearance, contrast and Reduce Transparency.
struct WindowMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// A real Liquid Glass surface for the menu-bar panel, not a simulated blur.
struct PanelGlass: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.style = .regular
        view.cornerRadius = 26
        view.tintColor = NSColor(srgbRed: 0.63, green: 0.55, blue: 0.79, alpha: 0.08)
        return view
    }
    func updateNSView(_ view: NSGlassEffectView, context: Context) {}
}

struct GlassIconButton: View {
    let title: String
    let symbol: String
    var action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: symbol).frame(width: 18, height: 22) }
            .buttonStyle(.glass).buttonBorderShape(.circle)
            .help(title).accessibilityLabel(title)
    }
}

struct InlineNotice: View {
    let text: String
    var isError = true
    var body: some View {
        Label(text, systemImage: isError ? "exclamationmark.circle" : "checkmark.circle")
            .font(.callout).foregroundStyle(isError ? Color.orange : Color.secondary)
            .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(.primary.opacity(0.045), in: .rect(cornerRadius: 14))
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).font(.system(size: 10, weight: .semibold)).tracking(1.3).foregroundStyle(.secondary) }
}
