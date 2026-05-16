import AppKit
import FactoryKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator: AppCoordinator

    override init() {
        coordinator = MainActor.assumeIsolated { AppCoordinator() }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        MainActor.assumeIsolated { self.coordinator.setup() }
        Task { @MainActor in
            await self.coordinator.viewModel.onAppear()
            print("[Voicy] App gestartet — Hotkey: Fn")
        }

        let onboardingDone = UserDefaults.standard.bool(forKey: Preferences.Key.onboardingCompleted)
        let firstLaunchDone = UserDefaults.standard.bool(forKey: Preferences.Key.firstLaunchCompleted)

        if !onboardingDone {
            // Close the auto-opened MainWindow and bring Onboarding to the front.
            DispatchQueue.main.async {
                NSApp.windows
                    .first(where: { $0.identifier?.rawValue == MainWindowID.id })?
                    .close()
                NSApp.windows
                    .first(where: { $0.identifier?.rawValue == OnboardingWindowID.id })?
                    .makeKeyAndOrderFront(nil)
            }
        } else if firstLaunchDone {
            NSApp.windows
                .first(where: { $0.identifier?.rawValue == MainWindowID.id })?
                .close()
        } else {
            UserDefaults.standard.set(true, forKey: Preferences.Key.firstLaunchCompleted)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag,
           let main = NSApp.windows.first(where: { $0.identifier?.rawValue == MainWindowID.id }) {
            main.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
