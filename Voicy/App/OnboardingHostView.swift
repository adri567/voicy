import AppKit
import SwiftUI

struct OnboardingHostView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    private var viewModel: RecordingViewModel? {
        (NSApp.delegate as? AppDelegate)?.coordinator.viewModel
    }

    var body: some View {
        OnboardingView(viewModel: viewModel) {
            UserDefaults.standard.set(true, forKey: Preferences.Key.onboardingCompleted)
            (NSApp.delegate as? AppDelegate)?.onboardingFinished()
            openWindow(id: MainWindowID.id)
            dismissWindow(id: OnboardingWindowID.id)
        }
        .frame(minWidth: 1280, minHeight: 820)
        .background(
            WindowCloseHandler {
                // The window can close two ways: a clean finish (which has
                // already flipped the flag to true above), or the user hits ⌘W
                // / the red traffic light. Only the latter should terminate.
                let done = UserDefaults.standard.bool(forKey: Preferences.Key.onboardingCompleted)
                if !done { NSApp.terminate(nil) }
            }
        )
    }
}
