import AppKit
import Observation
import Sparkle

/// Sparkle owns download, signature validation, replacement and relaunch.
@MainActor @Observable
final class AppUpdater: NSObject, @MainActor SPUStandardUserDriverDelegate, SPUUpdaterDelegate {
    private(set) var canCheck = false
    private(set) var availableVersion: String?
    private(set) var startupError: String?
    var canRelaunch: (() -> Bool)?
    var explainRelaunchDelay: (() -> Void)?
    var automaticallyChecks = false {
        didSet {
            if controller.updater.automaticallyChecksForUpdates != automaticallyChecks {
                controller.updater.automaticallyChecksForUpdates = automaticallyChecks
            }
        }
    }
    @ObservationIgnored private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []

    var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—" }

    func start() {
        do {
            try controller.updater.start()
            automaticallyChecks = controller.updater.automaticallyChecksForUpdates
            observations = [
                controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] _, change in
                    let enabled = change.newValue ?? false
                    Task { @MainActor in self?.canCheck = enabled }
                },
                controller.updater.observe(\.automaticallyChecksForUpdates, options: [.new]) { [weak self] _, change in
                    let enabled = change.newValue ?? false
                    Task { @MainActor in self?.automaticallyChecks = enabled }
                }
            ]
        } catch { startupError = "Güncelleyici başlatılamadı: \(error.localizedDescription)" }
    }

    func check() {
        guard canCheck else { return }
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    // A background menu app surfaces scheduled updates inside its existing panel.
    var supportsGentleScheduledUpdateReminders: Bool { true }
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool { false }
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        availableVersion = update.displayVersionString
    }
    func standardUserDriverWillFinishUpdateSession() { availableVersion = nil }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        guard canRelaunch?() == false else { return false }
        explainRelaunchDelay?()
        Task { @MainActor [weak self] in
            while self?.canRelaunch?() == false { try? await Task.sleep(for: .seconds(1)) }
            installHandler()
        }
        return true
    }
}
