import AppKit
import SwiftUI
import RenamerCore
import OSLog

@main
enum RenamerApplication {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var menuPanel: MenuBarPanel!
    private var settingsWindow: NSWindow?
    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger(subsystem: "com.erdemdev.texterifyrenamer", category: "lifecycle").notice("Application launched; installing status item")
        installMenu()
        model.updates.start()
        model.checkForUpdates = { [weak self] in self?.checkForUpdates() }
        model.updates.canRelaunch = { [weak self] in
            guard let self else { return true }
            return !model.busy && settingsWindow?.isVisible != true
        }
        model.updates.explainRelaunchDelay = { [weak self] in
            guard let self else { return }
            model.error = "Güncelleme hazır. Devam eden işlemin bitmesini bekle; eşleştirme penceresi açıksa değişikliklerini kaydedip kapat."
            show()
        }
        statusItem = NSStatusBar.system.statusItem(withLength: 30)
        if let button = statusItem.button {
            let target = StatusDropView(frame: button.bounds)
            target.autoresizingMask = [.width, .height]
            target.onClick = { [weak self] in self?.toggle() }
            target.onDrop = { [weak self] urls in self?.model.receive(urls) }
            target.onMenu = { [weak self] event, view in self?.contextMenu(event, view: view) }
            button.addSubview(target)
            button.toolTip = "Texterify Renamer — ZIP dosyasını bırak"
        }
        menuPanel = MenuBarPanel(model: model)
        model.openSettings = { [weak self] in self?.showSettings() }
        model.showPanel = { [weak self] in self?.show() }
        model.beforeDialog = { [weak self] in self?.menuPanel.close() }
        model.appearanceChanged = { [weak self] in self?.applyAppearance() }
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.refreshColorScheme() }
        }
        applyAppearance()
        // Let AppKit finish placing the status item before the first presentation.
        DispatchQueue.main.async { [weak self] in self?.show() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return true
    }

    private func installMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        let update = appMenu.addItem(withTitle: "Güncellemeleri denetle…", action: #selector(checkForUpdates), keyEquivalent: "")
        update.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Texterify Renamer’dan çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Düzen"); editItem.submenu = edit
        for (title, selector, key) in [("Geri al", "undo:", "z"), ("Kes", "cut:", "x"), ("Kopyala", "copy:", "c"), ("Yapıştır", "paste:", "v"), ("Tümünü seç", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key)
        }
        NSApp.mainMenu = main
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        model.receive(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard model.busy else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "İşlem devam ediyor"
        alert.informativeText = "Önce işlemi iptal et veya tamamlanmasını bekle."
        alert.addButton(withTitle: "Tamam")
        NSApp.activate(ignoringOtherApps: true); alert.runModal()
        return .terminateCancel
    }

    private func toggle() { if menuPanel.isShown { menuPanel.close() } else { show() } }
    @objc private func checkForUpdates() {
        guard !model.busy else { return }
        menuPanel.close()
        model.updates.check()
    }
    private func show() {
        guard let button = statusItem?.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        menuPanel.show(below: button)
    }

    @objc private func showSettings() {
        menuPanel.close()
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return
        }
        let controller = NSHostingController(rootView: SettingsView(model: model))
        controller.sceneBridgingOptions = [.toolbars]
        let window = NSWindow(contentViewController: controller)
        window.title = "Eşleştirmeler"
        window.subtitle = "Renamer"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .visible
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 780, height: 670))
        window.minSize = NSSize(width: 660, height: 570)
        window.appearance = NSApp.appearance
        window.titlebarAppearsTransparent = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.isReleasedWhenClosed = false
        if let screen = statusItem.button?.window?.screen ?? NSScreen.main {
            let visible = screen.visibleFrame.insetBy(dx: 24, dy: 24)
            var frame = window.frame
            frame.size.width = min(frame.width, visible.width)
            frame.size.height = min(frame.height, visible.height)
            frame.origin = NSPoint(x: visible.midX - frame.width / 2, y: visible.midY - frame.height / 2)
            window.setFrame(frame, display: false)
        } else { window.center() }
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
    }

    private func applyAppearance() {
        switch model.appearance {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
        refreshColorScheme()
        menuPanel.appearance = NSApp.appearance
        settingsWindow?.appearance = NSApp.appearance
    }

    private func refreshColorScheme() {
        // Resolve System explicitly: resetting preferredColorScheme to nil can leave
        // an existing AppKit popover hosting view in its previous appearance.
        model.colorScheme = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .dark : .light
    }

    private func contextMenu(_ event: NSEvent, view: NSView) {
        let menu = NSMenu()
        let settings = menu.addItem(withTitle: "Eşleştirmeler…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        let update = menu.addItem(withTitle: "Güncellemeleri denetle…", action: #selector(checkForUpdates), keyEquivalent: "")
        update.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(checkForUpdates) { return model.updates.canCheck && !model.busy }
        return true
    }
}

/// A real AppKit dragging destination over the status button; a SwiftUI panel-only
/// drop handler cannot receive a file dropped on the menu bar icon itself.
final class StatusDropView: NSView {
    var onClick: (() -> Void)?
    var onDrop: (([URL]) -> Void)?
    var onMenu: ((NSEvent, NSView) -> Void)?
    private var highlighted = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Texterify Renamer")
        setAccessibilityHelp("Paneli aç veya bir ZIP dosyası bırak.")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func draw(_ dirtyRect: NSRect) {
        if highlighted { NSColor.controlAccentColor.withAlphaComponent(0.25).setFill(); NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4).fill() }
        let image = NSImage(systemSymbolName: "doc.zipper", accessibilityDescription: "Texterify Renamer")
        image?.isTemplate = true
        image?.draw(in: NSRect(x: (bounds.width - 16) / 2, y: (bounds.height - 18) / 2, width: 16, height: 18))
    }
    override func mouseDown(with event: NSEvent) { onClick?() }
    override func rightMouseDown(with event: NSEvent) { onMenu?(event, self) }
    override func accessibilityPerformPress() -> Bool { onClick?(); return true }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let valid = urls(sender).count == 1 && urls(sender).first?.pathExtension.lowercased() == "zip"
        highlighted = valid; needsDisplay = true
        return valid ? .copy : []
    }
    override func draggingExited(_ sender: NSDraggingInfo?) { highlighted = false; needsDisplay = true }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        highlighted = false; needsDisplay = true
        let files = urls(sender)
        guard files.count == 1 else { return false }
        onDrop?(files); return true
    }
    private func urls(_ sender: NSDraggingInfo) -> [URL] {
        sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }
}
