import FactoryKit
import SwiftUI

/// Hidden Developer section, shown by `SettingsView` once unlocked (7 taps on
/// the version number). Gathers the power-user/debug controls in one place.
/// Pure UI — the unlock state and actions live in `DeveloperSettingsViewModel`.
struct DeveloperSection: View {
    let developer: DeveloperSettingsViewModel
    var recording: RecordingViewModel

    @State private var showingResetConfirmation = false

    #if DEBUG
    @Injected(\.entitlementService) private var entitlement
    @Environment(EntitlementStore.self) private var entitlementStore
    #endif

    var body: some View {
        SettingsSection(title: "Developer", caption: "Hidden tools — power users & debugging") {
                SettingsToggleRow(
                    label: "Transcript popup after recording",
                    desc: "Briefly shows the result as a popup above the menu bar.",
                    value: Binding(
                        get: { recording.showTranscript },
                        set: { _ in recording.toggleShowTranscript() }
                    ),
                    isMock: false
                )

                OnboardingResetRow()

                SettingsActionRow(
                    label: "Reveal model folders",
                    description: "Opens the on-disk locations of the Whisper, MLX and Parakeet models in Finder.",
                    buttonTitle: "Reveal",
                    systemImage: "folder",
                    action: { developer.revealModelFolders() }
                )

                SettingsActionRow(
                    label: "Open Console",
                    description: "Launches Console.app to inspect Voicy's unified logs.",
                    buttonTitle: "Open",
                    systemImage: "doc.text.magnifyingglass",
                    action: { developer.openConsole() }
                )

                #if DEBUG
                SettingsToggleRow(
                    label: "Pro entitlement",
                    desc: "Debug builds only. Simulates a Pro subscription; updates every gate live.",
                    value: Binding(
                        get: { entitlement.isPro },
                        set: { newValue in
                            entitlement.setPro(newValue)
                            entitlementStore.refresh()
                        }
                    ),
                    isMock: false
                )
                #endif

                #if DEBUG
                // Debug builds only: wipes usage counters, so it must never ship
                // — otherwise a Free user could reset their weekly limit at will.
                SettingsDangerButtonRow(
                    label: "Reset app data",
                    description: "Clears usage counters, plan flag and onboarding state, then relaunches. Models and an active license are kept.",
                    action: { showingResetConfirmation = true }
                )
                #endif

                SettingsActionRow(
                    label: "Hide developer tools",
                    description: "Collapses this section. Tap the version number 7× to bring it back.",
                    buttonTitle: "Hide",
                    systemImage: "eye.slash",
                    action: { developer.hideDeveloperTools() }
                )
            }
            .alert("Reset app data?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset & Relaunch", role: .destructive) { developer.resetAppData() }
            } message: {
                Text("Usage counters, the plan flag and onboarding state will be cleared and Voicy will relaunch. Downloaded models are kept.")
            }
    }
}
