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
            .environment(Container.shared.entitlementStore())
            // Voicy ships a single light "paper" design (DS.Palette has no dark
            // variants). Pin the light scheme so system-driven bits — text-field
            // placeholders, carets, separators — don't invert under macOS dark mode.
            .preferredColorScheme(.light)
        }
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .modelContainer(Container.shared.modelContainer())

        Window("Voicy — Onboarding", id: OnboardingWindowID.id) {
            OnboardingHostView()
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1440, height: 860)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
    }
}
