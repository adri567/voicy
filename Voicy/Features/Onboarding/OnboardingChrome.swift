import SwiftUI

struct OnboardingChrome: View {
    @Bindable var state: OnboardingState

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            // Left: back button (real macOS traffic lights live in the title bar)
            HStack(spacing: 16) {
                if state.stepIndex > 0 {
                    Button(action: { state.back() }) {
                        Text("← BACK")
                            .font(DS.Font.mono(10, weight: .regular))
                            .tracking(1.2)
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 180, alignment: .leading)

            // Center: chapter / title
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Ch. \(state.step.chapter)")
                    .font(DS.Font.mono(10))
                    .tracking(1.4)
                    .foregroundStyle(DS.Palette.ink3)
                HStack(spacing: 4) {
                    Text("Voicy")
                        .font(DS.Font.serif(16, weight: .medium))
                        .foregroundStyle(DS.Palette.ink2)
                    Text("— \(state.step.title)")
                        .font(DS.Font.serifItalic(16))
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            .frame(maxWidth: .infinity)

            // Right: stepper dots + counter
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Text(String(format: "%02d / %02d",
                            state.stepIndex + 1,
                            OnboardingStep.allCases.count))
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                HStack(spacing: 4) {
                    ForEach(OnboardingStep.allCases) { s in
                        Button(action: { state.goTo(s.rawValue) }) {
                            Capsule()
                                .fill(dotColor(for: s.rawValue))
                                .frame(width: s.rawValue == state.stepIndex ? 18 : 6, height: 6)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.22), value: state.stepIndex)
                    }
                }
            }
            .frame(width: 220, alignment: .trailing)
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(DS.Palette.paper2)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.Palette.ruleSoft).frame(height: 1)
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < state.stepIndex { return DS.Palette.ink2 }
        if index == state.stepIndex { return DS.Palette.accent }
        return DS.Palette.ink.opacity(0.16)
    }
}

