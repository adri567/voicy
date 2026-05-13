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

        let firstLaunchDone = UserDefaults.standard.bool(forKey: Preferences.Key.firstLaunchCompleted)
        if firstLaunchDone {
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
                languageCycleService: appDelegate.coordinator.languageCycleService
            )
        }
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .modelContainer(Container.shared.modelContainer())
    }
}
