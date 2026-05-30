import SwiftUI

struct FnKeyScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            kicker: "One last setting",
            title: { titleView },
            lead: nil,
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        let lead = Text("Free up the ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
        let accent = Text("Fn key.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
        return Text("\(lead)\(accent)")
            .tracking(-1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leftBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("By default, macOS pops up the **Emoji & Symbols** picker when you press the Fn / 🌐 key. Voicy uses Fn as its hotkey, so we need to free it up. Click the button on the right and Voicy will set it for you — or do it manually in System Settings if you prefer.")
                .font(DS.Font.sans(16))
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 460, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                MetaLabel(text: "What Voicy changes")
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(DS.Palette.ink3)
                    Text("Sets **Press 🌐 key to → Do Nothing** in your Keyboard preferences. Nothing else.")
                        .font(DS.Font.sans(13))
                        .lineSpacing(3)
                        .foregroundStyle(DS.Palette.ink2)
                }
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(DS.Palette.ink3)
                    Text("You can revert this any time in System Settings → Keyboard.")
                        .font(DS.Font.sans(13))
                        .lineSpacing(3)
                        .foregroundStyle(DS.Palette.ink2)
                }
            }
            .padding(20)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.panel).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
    }

    private var footer: some View {
        NavFooter(
            primary: "Continue →",
            primaryDisabled: state.fnKeyState != .granted,
            onContinue: { state.next() },
            note: state.fnKeyState == .granted ? "Fn key is free" : "Fn key must be freed up",
            onBack: { state.back() }
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        VStack(alignment: .leading, spacing: 18) {
            MetaLabel(text: "System Settings → Keyboard")

            // Mock System Settings keyboard pane
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25)).frame(width: 11, height: 11)
                    Text("Keyboard")
                        .font(DS.Font.sans(12, weight: .medium))
                        .foregroundStyle(DS.Palette.ink2)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Color(red: 0.961, green: 0.953, blue: 0.933).opacity(0.7))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.black.opacity(0.05)).frame(height: 0.5)
                }

                VStack(spacing: 0) {
                    keyboardRow(label: "Key repeat rate", value: "Fast", highlight: false)
                    keyboardRow(label: "Press 🌐 key to", value: state.fnKeyState == .granted ? "Do Nothing" : "Show Emoji & Symbols", highlight: true)
                    keyboardRow(label: "Press Fn key to", value: "Change Input Source", highlight: false)
                }
            }
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    if state.fnKeyState != .granted {
                        Button(action: {
                            state.disableFnKey()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "wand.and.sparkles")
                                Text("Free up Fn key")
                            }
                            .font(DS.Font.sans(13, weight: .semibold))
                            .foregroundStyle(DS.Palette.paper)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(DS.Palette.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: {
                        state.openKeyboardPane()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.forward.square")
                            Text("Open Keyboard Settings")
                        }
                        .font(DS.Font.sans(12, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(DS.Palette.paper, in: Capsule())
                        .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                if state.fnKeyState == .granted {
                    Text("● Fn key is yours")
                        .font(DS.Font.mono(10))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.accentInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.Palette.accent2, in: Capsule())
                }
            }
        }
        .padding(36)
        .task {
            while !Task.isCancelled {
                state.syncFnKeyFromSystem()
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
    }

    private func keyboardRow(label: String, value: String, highlight: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(DS.Font.sans(13, weight: highlight ? .semibold : .medium))
                .foregroundStyle(DS.Palette.ink)
            if highlight {
                Text("← SET TO 'DO NOTHING'")
                    .font(DS.Font.mono(9))
                    .tracking(1.2)
                    .foregroundStyle(DS.Palette.accent)
            }
            Spacer()
            HStack(spacing: 6) {
                Text(value)
                    .font(DS.Font.sans(12))
                    .foregroundStyle(DS.Palette.ink2)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(highlight ? DS.Palette.accent.opacity(0.4) : DS.Palette.ruleSoft, lineWidth: highlight ? 2 : 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(highlight ? DS.Palette.accent.opacity(0.06) : Color.clear)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.05)).frame(height: 0.5)
        }
    }
}
