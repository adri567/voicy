import SwiftUI

struct OnboardingResetRow: View {

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Replay onboarding")
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Text("Clears the completed flag, closes this window, and reopens the first-run tour. Useful for testing.")
                    .font(DS.Font.sans(11))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
                    .frame(maxWidth: 440, alignment: .leading)
            }
            Spacer()
            Button(action: resetOnboarding) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Replay")
                }
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 18)
    }

    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Preferences.Key.onboardingCompleted)
        openWindow(id: OnboardingWindowID.id)
        dismissWindow(id: MainWindowID.id)
    }
}
