import SwiftUI

struct WelcomeScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 44, height: 44)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DS.Palette.ink)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "waveform")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(DS.Palette.accentInk)
                            )
                    }
                    Text("Voicy")
                        .font(.system(size: 56, weight: .semibold))
                        .tracking(-1.96)
                        .foregroundStyle(DS.Palette.ink)
                }
                .padding(.bottom, 28)

                let lead = Text("Your voice, ")
                    .font(DS.Font.serif(64, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                let accent = Text("set in type.")
                    .font(DS.Font.serifItalic(64, weight: .medium))
                    .foregroundStyle(DS.Palette.accent)
                Text("\(lead)\(accent)")
                    .tracking(-1.6)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-4)
                    .frame(maxWidth: 880)

                Text("Hold a key. Speak. Voicy transcribes locally and drops the words wherever your cursor is — in Mail, Linear, Slack, the terminal, anywhere.")
                    .font(DS.Font.sans(18))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 560)
                    .padding(.top, 22)

                PrimaryButton(title: "Begin Setup") {
                    state.next()
                }
                .padding(.top, 38)
            }
            .padding(.horizontal, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Palette.paper)
    }
}
