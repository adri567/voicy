import SwiftUI

struct AllSetScreen: View {
    @Bindable var state: OnboardingState
    let onFinish: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            leftColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 56)
                .padding(.vertical, 48)
                .background(DS.Palette.paper)
                .overlay(alignment: .trailing) {
                    Rectangle().fill(DS.Palette.ruleSoft).frame(width: 1)
                }

            rightColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 56)
                .padding(.vertical, 48)
                .background(DS.Palette.paper2)
        }
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "◆ Chapter 07 — Ready", color: DS.Palette.accent)

            (Text("You're ")
                .font(DS.Font.serif(64, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
             + Text("ready\n")
                .font(DS.Font.serifItalic(64, weight: .medium))
                .foregroundStyle(DS.Palette.accent)
             + Text("to speak.")
                .font(DS.Font.serif(64, weight: .medium))
                .foregroundStyle(DS.Palette.ink))
            .tracking(-1.6)
            .lineSpacing(-6)
            .padding(.top, 20)

            Text("Voicy lives in your menu bar. Hold your hotkey from anywhere — any app, any input — and the words land where the cursor blinks.")
                .font(DS.Font.sans(16))
                .lineSpacing(5)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 420, alignment: .leading)
                .padding(.top, 22)

            Spacer(minLength: 24)

            MetaLabel(text: "A few things worth knowing")
                .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 6) {
                tip("Say \u{201C}new paragraph\u{201D} to break — or \u{201C}scratch that\u{201D} to undo the last sentence.")
                tip("Hold ⇧ while dictating to translate live into your primary language.")
                tip("Open the Voicy app for your full Verlauf — every transcript is searchable.")
            }

            HStack(spacing: 12) {
                PrimaryButton(title: "Open Voicy →") {
                    state.persistFinalChoices()
                    onFinish()
                }
                GhostButton(title: "← Review") { state.back() }
            }
            .padding(.top, 28)
        }
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("◆").foregroundStyle(DS.Palette.accent)
            Text(text)
                .font(DS.Font.sans(13))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            MetaLabel(text: "Your setup, in summary")

            VStack(spacing: 0) {
                summaryRow(label: "Microphone",
                           value: state.micPermission == .granted ? "Granted" : "Not granted",
                           ok: state.micPermission == .granted)
                summaryRow(label: "Accessibility",
                           value: state.a11yPermission == .granted ? "Granted" : "Pending",
                           ok: state.a11yPermission == .granted)
                summaryRow(label: "Voice model",
                           value: "\(state.pickedModel.family) \(state.pickedModel.label) · \(state.pickedModel.displaySize)",
                           ok: true)
                summaryRow(label: "Brain",
                           value: state.pickedBrain.map { "\($0.name) \($0.variant) · \($0.size)" }
                            ?? "None — pure dictation",
                           ok: true,
                           optional: state.pickedBrain == nil)
                summaryRow(label: "Language",
                           value: "\(state.pickedLanguage.native) · \(state.pickedLanguage.code.uppercased())",
                           ok: true)
                summaryRow(label: "Click sounds",
                           value: state.clickSounds ? "On" : "Off",
                           ok: true, last: true)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 6)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 10) {
                MetaLabel(text: "Final preferences")
                togglePreference
            }
            .padding(.top, 6)

            Spacer(minLength: 16)

            promiseCard
        }
    }

    private var togglePreference: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Open Voicy at login")
                    .font(DS.Font.sans(14, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Text("Voicy quietly starts in your menu bar each time you sign in.")
                    .font(DS.Font.sans(12))
                    .foregroundStyle(DS.Palette.ink3)
            }
            Spacer()
            Toggle("", isOn: $state.openAtLogin)
                .toggleStyle(.switch)
                .tint(DS.Palette.accent2)
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(DS.Palette.ruleSoft, lineWidth: 1)
        )
    }

    private var promiseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MetaLabel(text: "◆ The Voicy promise", color: DS.Palette.accentInk.opacity(0.55))
            (Text("Your voice never leaves this Mac. ")
                .font(DS.Font.serif(19, weight: .medium))
                .foregroundStyle(DS.Palette.accentInk)
             + Text("Full stop.")
                .font(DS.Font.serifItalic(19, weight: .medium))
                .foregroundStyle(DS.Palette.accent))
            Text("No cloud transcription, no analytics on what you say, no model improvements trained from your words.")
                .font(DS.Font.sans(12))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.accentInk.opacity(0.7))
        }
        .padding(20)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: 14))
    }

    private func summaryRow(
        label: String, value: String, ok: Bool,
        last: Bool = false, optional: Bool = false
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            MetaLabel(text: label)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(DS.Font.sans(13, weight: .medium))
                .foregroundStyle(optional ? DS.Palette.ink3 : DS.Palette.ink)
                .italic(optional)
            Spacer()
            ZStack {
                Circle()
                    .fill(optional ? Color.clear : (ok ? DS.Palette.accent2 : Color.clear))
                    .frame(width: 18, height: 18)
                if optional {
                    Circle().stroke(DS.Palette.ruleSoft, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(width: 18, height: 18)
                    Text("—").font(.system(size: 10, weight: .bold)).foregroundStyle(DS.Palette.ink3)
                } else if ok {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Palette.accentInk)
                }
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if !last { Rectangle().fill(DS.Palette.ruleSoft).frame(height: 1) }
        }
    }
}

private extension View {
    @ViewBuilder
    func italic(_ on: Bool) -> some View {
        if on { self.italic() } else { self }
    }
}
