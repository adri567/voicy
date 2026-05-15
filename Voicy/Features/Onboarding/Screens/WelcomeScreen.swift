import SwiftUI

struct WelcomeScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ZStack {
            // Faint center rule
            Rectangle()
                .fill(DS.Palette.ruleSoft)
                .frame(width: 1)
                .padding(.vertical, 60)

            VStack(spacing: 0) {
                MetaLabel(text: "◆ The Voicy Press — Established 2026", color: DS.Palette.accent)
                    .padding(.bottom, 22)

                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.Palette.ink)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "waveform")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(DS.Palette.accentInk)
                        )
                    Text("Voicy")
                        .font(.system(size: 56, weight: .semibold))
                        .tracking(-1.96)
                        .foregroundStyle(DS.Palette.ink)
                }
                .padding(.bottom, 28)

                (Text("Your voice, ")
                    .font(DS.Font.serif(64, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                 + Text("set in type.")
                    .font(DS.Font.serifItalic(64, weight: .medium))
                    .foregroundStyle(DS.Palette.accent))
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

                PrimaryButton(title: "Begin setup — takes 2 minutes →") {
                    state.next()
                }
                .padding(.top, 38)

                HStack(spacing: 22) {
                    Text("↑↓ ←→ TO NAVIGATE")
                    Text("·")
                    Text("ESC TO QUIT")
                    Text("·")
                    Text("v0.4 BETA")
                }
                .font(DS.Font.mono(9))
                .tracking(1.2)
                .foregroundStyle(DS.Palette.ink3)
                .padding(.top, 40)
            }
            .padding(.horizontal, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Palette.paper)
    }
}
