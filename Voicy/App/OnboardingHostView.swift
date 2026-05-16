import SwiftUI

struct OnboardingHostView: View {
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
