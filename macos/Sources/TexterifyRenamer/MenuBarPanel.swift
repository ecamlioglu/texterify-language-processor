import AppKit
import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
private final class MenuPanelLayout {
    var availableHeight: CGFloat = 700
    var width: CGFloat = 408
}

/// Anchor a native popover to an explicitly positioned, transparent 1-point
/// window below the menu bar. Never pass the status item's transient launch
/// geometry to NSPopover, which can otherwise choose an unintended screen edge.
@MainActor
final class MenuBarPanel: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let anchorWindow = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: true)
    private let anchorView = NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
    private let layout = MenuPanelLayout()
    private weak var anchorButton: NSStatusBarButton?
    private var contentHeight: CGFloat = 380
    private var presentationTask: Task<Void, Never>?
    private var screenObserver: NSObjectProtocol?
    var isShown: Bool { popover.isShown }
    var appearance: NSAppearance? {
        get { popover.appearance }
        set { popover.appearance = newValue }
    }

    init(model: AppModel) {
        super.init()
        anchorWindow.contentView = anchorView
        anchorWindow.isOpaque = false
        anchorWindow.backgroundColor = .clear
        anchorWindow.hasShadow = false
        anchorWindow.ignoresMouseEvents = true
        anchorWindow.isReleasedWhenClosed = false
        anchorWindow.level = .statusBar
        anchorWindow.collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        popover.delegate = self
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(rootView: MenuPanelRoot(model: model, layout: layout) { [weak self] height in
            guard let self, height > 0, abs(self.contentHeight - height) > 0.5 else { return }
            self.contentHeight = height
            Task { @MainActor [weak self] in self?.updateSize() }
        })
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.close() }
        }
    }

    func show(below button: NSStatusBarButton) {
        anchorButton = button
        presentationTask?.cancel()
        if presentIfReady() { return }
        presentationTask = Task { @MainActor [weak self] in
            for _ in 0..<10 {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                guard let self, NSApp.isActive else { return }
                if self.presentIfReady() { return }
            }
        }
    }

    private func presentIfReady() -> Bool {
        guard let button = anchorButton, let window = button.window, let screen = window.screen else { return false }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = screen.visibleFrame
        // Status item windows initially have height zero and an offscreen origin.
        // Validate against the physical screen top also when the menu bar auto-hides.
        guard window.frame.height > 0,
              anchor.midX >= screen.frame.minX, anchor.midX <= screen.frame.maxX,
              anchor.midY >= screen.frame.maxY - max(64, screen.safeAreaInsets.top + NSStatusBar.system.thickness),
              anchor.midY <= screen.frame.maxY else { return false }
        let menuBottom = min(anchor.minY, visible.maxY)
        let tipY = menuBottom - 12
        layout.width = min(408, visible.width - 24)
        layout.availableHeight = max(1, tipY - visible.minY - 40)
        anchorWindow.setFrame(NSRect(x: anchor.midX - 0.5, y: tipY, width: 1, height: 1), display: false)
        anchorWindow.orderFront(nil)
        updateSize()
        NSApp.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
        }
        popover.contentViewController?.view.window?.makeKey()
        recordPlacement()
        return true
    }

    private func updateSize() {
        popover.contentSize = NSSize(width: layout.width, height: min(contentHeight, layout.availableHeight))
        if popover.isShown { recordPlacement() }
    }

    private func recordPlacement() {
        guard let frame = popover.contentViewController?.view.window?.frame,
              let screen = anchorButton?.window?.screen else { return }
        Logger(subsystem: "com.erdemdev.texterifyrenamer", category: "panel-placement")
            .notice("menuBottom=\(screen.visibleFrame.maxY) panelTop=\(frame.maxY) panelBottom=\(frame.minY) anchorTip=\(self.anchorWindow.frame.minY)")
    }

    func close() { presentationTask?.cancel(); popover.close(); anchorWindow.orderOut(nil) }
    func popoverDidClose(_ notification: Notification) { anchorWindow.orderOut(nil) }
}

private struct MenuPanelRoot: View {
    @Bindable var model: AppModel
    var layout: MenuPanelLayout
    var heightChanged: (CGFloat) -> Void
    @State private var measuredHeight: CGFloat = 380

    var body: some View {
        ScrollView {
            PanelView(model: model)
                .frame(width: layout.width)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    measuredHeight = height
                    heightChanged(height)
                }
        }
        .scrollIndicators(.hidden)
        .scrollDisabled(measuredHeight <= layout.availableHeight)
        .frame(width: layout.width, height: min(measuredHeight, layout.availableHeight))
        .background { SoftBackdrop(panel: true).clipShape(.rect(cornerRadius: 26)).ignoresSafeArea() }
        .preferredColorScheme(model.colorScheme)
        .tint(AppPalette.accent)
    }
}
