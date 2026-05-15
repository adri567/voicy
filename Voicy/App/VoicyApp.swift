import AppKit
import FactoryKit
import SwiftData
import SwiftUI

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

enum MainWindowID {
    static let id = "main"
}

enum OnboardingWindowID {
    static let id = "onboarding"
}

@main
struct VoicyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarStatusView(viewModel: appDelegate.coordinator.viewModel)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)

        Window("Voicy", id: MainWindowID.id) {
            MainWindowView(
                viewModel: appDelegate.coordinator.viewModel,
                modeCycleService: appDelegate.coordinator.modeCycleService
            )
        }
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .modelContainer(Container.shared.modelContainer())

        Window("Voicy — Onboarding", id: OnboardingWindowID.id) {
            OnboardingHostView()
        }
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
    }
}

private struct OnboardingHostView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        OnboardingView {
            UserDefaults.standard.set(true, forKey: Preferences.Key.onboardingCompleted)
            openWindow(id: MainWindowID.id)
            dismissWindow(id: OnboardingWindowID.id)
        }
        .frame(minWidth: 1280, minHeight: 820)
    }
}
