import AppKit
import FactoryKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) let coordinator: AppCoordinator

    override init() {
        coordinator = MainActor.assumeIsolated { AppCoordinator() }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated { self.coordinator.setup() }
        Task { @MainActor in
            await self.coordinator.viewModel.onAppear()
            print("[Voicy] App gestartet — Hotkey: Ctrl+Option")
        }
    }
}

@main
struct VoicyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarStatusView(viewModel: appDelegate.coordinator.viewModel)
        } label: {
            Image(systemName: appDelegate.coordinator.viewModel.menuBarIconName)
        }
        .menuBarExtraStyle(.window)
    }
}
