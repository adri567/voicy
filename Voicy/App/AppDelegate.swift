import AppKit
import FactoryKit
import Foundation
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator: AppCoordinator

    override init() {
        coordinator = MainActor.assumeIsolated { AppCoordinator() }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start crash reporting first so early-launch failures are captured.
        // No-op unless a real Sentry DSN is bundled and the user hasn't opted out.
        Container.shared.telemetryService().start()

        NSApp.setActivationPolicy(.regular)

        let onboardingDone = UserDefaults.standard.bool(forKey: Preferences.Key.onboardingCompleted)

        // Spin up the recording stack regardless of onboarding state. setup()
        // is idempotent and no longer triggers permission prompts — the
        // PracticeScreen relies on this so the user can really test Fn-hold
        // before completing the onboarding.
        MainActor.assumeIsolated { self.coordinator.setup() }
        Task { @MainActor in
            await self.coordinator.viewModel.onAppear()
            Log.app.info("App started — hotkey: Fn")
        }

        // Re-validate the stored license in the background, then sync the
        // observable mirror so a downgrade (lapsed subscription) reflects in the
        // UI live — no relaunch needed.
        Task { @MainActor in
            await Container.shared.licenseService().refreshEntitlement()
            Container.shared.entitlementStore().refresh()
        }

        if !onboardingDone {
            // Close the auto-opened MainWindow and bring Onboarding to the
            // front. SwiftUI opens the first declared Window on launch, which
            // is MainWindow — we swap it for Onboarding until setup is done.
            DispatchQueue.main.async {
                NSApp.windows
                    .first(where: { $0.identifier?.rawValue == MainWindowID.id })?
                    .close()
                NSApp.windows
                    .first(where: { $0.identifier?.rawValue == OnboardingWindowID.id })?
                    .makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    /// Invoked by the onboarding host once the user finishes setup. setup()
    /// is idempotent. The model warm-up is forced (`reloadActiveModel`) because
    /// the engine may have just changed during onboarding and the launch-time
    /// `onAppear` likely ran with the old engine + no model on disk.
    @MainActor
    func onboardingFinished() {
        coordinator.setup()
        Task { @MainActor in
            await self.coordinator.viewModel.reloadActiveModel()
            Log.app.info("Onboarding finished — hotkey: Fn")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        let onboardingDone = UserDefaults.standard.bool(forKey: Preferences.Key.onboardingCompleted)
        let targetID = onboardingDone ? MainWindowID.id : OnboardingWindowID.id
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == targetID }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
}
