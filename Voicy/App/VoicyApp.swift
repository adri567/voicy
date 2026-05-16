import FactoryKit
import SwiftData
import SwiftUI

@main
struct VoicyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        HistoryMigration.runIfNeeded(container: Container.shared.modelContainer())
    }

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
