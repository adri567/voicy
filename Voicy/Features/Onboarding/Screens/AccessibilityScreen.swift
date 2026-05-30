import SwiftUI

struct AccessibilityScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            kicker: "Permission",
            title: { titleView },
            lead: nil,
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        let lead = Text("Then, ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
        let accent = Text("let us type for you.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
        return Text("\(lead)\(accent)")
            .tracking(-1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leftBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("macOS keeps a tight grip on apps that simulate keystrokes — for good reason. To drop transcribed text into Mail, Slack, or your editor, Voicy needs **Accessibility** permission. We only use it to paste your words at the cursor.")
                .font(DS.Font.sans(16))
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 460, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                MetaLabel(text: "What Voicy will NEVER do")
                ForEach(["Read what's on your screen",
                         "Log keystrokes outside of dictation",
                         "Send anything to a server without your consent"], id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(DS.Palette.ink3)
                        Text(item)
                            .font(DS.Font.sans(13))
                            .lineSpacing(3)
                            .foregroundStyle(DS.Palette.ink2)
                    }
                }
            }
            .padding(20)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.panel).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
    }

    private var footer: some View {
        NavFooter(
            primary: "Continue →",
            primaryDisabled: state.a11yPermission != .granted,
            onContinue: { state.next() },
            note: state.a11yPermission == .granted ? "Permission granted" : "Accessibility access required",
            onBack: { state.back() }
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        VStack(alignment: .leading, spacing: 18) {
            MetaLabel(text: "System Settings → Privacy & Security → Accessibility")

            // Mock System Settings panel
            VStack(spacing: 0) {
                // fake titlebar
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25)).frame(width: 11, height: 11)
                    Text("Accessibility")
                        .font(DS.Font.sans(12, weight: .medium))
                        .foregroundStyle(DS.Palette.ink2)
                        .padding(.leading, 8)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Color(red: 0.961, green: 0.953, blue: 0.933).opacity(0.7))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.black.opacity(0.1)).frame(height: 0.5)
                }

                VStack(spacing: 0) {
                    a11yRow(name: "Voicy", on: state.a11yPermission == .granted, highlight: true)
                }
            }
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

            HStack(spacing: 12) {
                if state.a11yPermission != .granted {
                    Button(action: {
                        state.requestAccessibility()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.forward.square")
                            Text("Open System Settings")
                        }
                        .font(DS.Font.sans(12, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(DS.Palette.paper, in: Capsule())
                        .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("● Voicy is now allowed to type")
                        .font(DS.Font.mono(10))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.accentInk)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.Palette.accent2, in: Capsule())
                }
                Text("You may be asked for your password.")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
            }
        }
        .padding(36)
        .task {
            // Re-poll permission while the screen is visible so that
            // approving in System Settings updates the UI right away.
            while !Task.isCancelled {
                state.syncAccessibilityFromSystem()
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
    }

    private func a11yRow(name: String, on: Bool, highlight: Bool = false) -> some View {
        HStack(spacing: 12) {
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(DS.Palette.ink)
                    .frame(width: 26, height: 26)
            }
            HStack(spacing: 8) {
                Text(name)
                    .font(DS.Font.sans(13, weight: highlight ? .semibold : .medium))
                    .foregroundStyle(DS.Palette.ink)
                if highlight {
                    Text("← TURN THIS ON")
                        .font(DS.Font.mono(9))
                        .tracking(1.2)
                        .foregroundStyle(DS.Palette.accent)
                }
            }
            Spacer()
            a11yToggle(on: on, highlight: highlight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(highlight ? DS.Palette.accent.opacity(0.06) : Color.clear)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.05)).frame(height: 0.5)
        }
    }

    private func a11yToggle(on: Bool, highlight: Bool) -> some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule()
                .fill(on ? Color(red: 0.165, green: 0.541, blue: 0.282) : Color.black.opacity(0.18))
                .frame(width: 38, height: 22)
            Circle()
                .fill(.white)
                .frame(width: 18, height: 18)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
        }
        .overlay(
            Capsule()
                .stroke(highlight && !on ? DS.Palette.accent.opacity(0.4) : .clear, lineWidth: 3)
        )
        .animation(.easeOut(duration: 0.22), value: on)
    }
}
