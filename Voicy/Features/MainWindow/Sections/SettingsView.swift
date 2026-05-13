import SwiftUI

struct SettingsView: View {

    var viewModel: RecordingViewModel

    // MOCK state — not persisted, not wired to system. TODO(settings-impl).
    @State private var launchAtLogin = false
    @State private var menuBarIcon = true
    @State private var soundOnStart = true
    @State private var autoPunct = true
    @State private var saveLocal = true
    @State private var usage = false
    @State private var updates = "stable"
    @State private var sensitivity: Double = 60
    @State private var device = "MacBook Pro Microphone"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.vertical, 32)

                sections
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
    }

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ Preferences", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("The little knobs \(Text("that").italic().foregroundColor(DS.Palette.accent)) shape how Voicy behaves.")
                    .font(DS.Font.serif(50))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 16)

                Text("Quiet preferences for a quiet app. Nothing here leaves your Mac unless you explicitly opt in.")
                    .font(DS.Font.sans(15))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 540, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            aboutCard
                .frame(width: 320)
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "About this build", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 12)

            Text("Voicy \(Text(version).italic())")
                .font(DS.Font.serif(28))
                .foregroundStyle(DS.Palette.paper)
                .padding(.bottom, 10)

            Text("Apple Silicon · macOS 26+\nReleased \(releaseDate)\nLocal-first · no audio leaves your Mac")
                .font(DS.Font.mono(11))
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.paper.opacity(0.7))
                .padding(.bottom, 18)

            HStack(spacing: 8) {
                aboutButton("Check for updates", filled: true)   // TODO(updates)
                aboutButton("Release notes", filled: false)      // TODO(release-notes)
            }
        }
        .padding(26)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
    }

    private func aboutButton(_ label: String, filled: Bool) -> some View {
        Button(label) {}
            .buttonStyle(.plain)
            .font(DS.Font.sans(11, weight: .medium))
            .foregroundStyle(filled ? DS.Palette.paper : DS.Palette.paper.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(filled ? Color.white.opacity(0.1) : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(filled ? 0.2 : 0.15), lineWidth: 1))
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 36) {

            SettingsSection(title: "General", caption: "How Voicy starts up and lives on your Mac") {
                AnyView(ToggleRow(label: "Launch at login",
                                  desc: "Have Voicy start automatically when you sign in.",
                                  value: $launchAtLogin,
                                  isMock: true))   // TODO(launch-at-login)
                AnyView(ToggleRow(label: "Show menu bar icon",
                                  desc: "A small waveform in the menu bar — click for quick controls.",
                                  value: $menuBarIcon,
                                  isMock: true))   // TODO(menubar-toggle)
                AnyView(ToggleRow(label: "Play a sound on start / stop",
                                  desc: "A soft click when dictation begins and ends.",
                                  value: $soundOnStart,
                                  isMock: true))   // TODO(sound-toggle)
            }

            SettingsSection(title: "Audio", caption: "The microphone and how Voicy listens") {
                AnyView(SelectRow(label: "Input device",
                                  desc: "Pick which microphone Voicy listens to.",
                                  value: $device,
                                  options: ["MacBook Pro Microphone", "Studio Display Microphone", "AirPods Pro (2)"],
                                  isMock: true))   // TODO(audio-input)
                AnyView(SliderRow(label: "Trigger sensitivity",
                                  desc: "How quickly Voicy starts capturing once you hold the key.",
                                  value: $sensitivity, min: 0, max: 100, suffix: "%",
                                  isMock: true))   // TODO(sensitivity)
            }

            SettingsSection(title: "Transcription", caption: "Defaults the engine uses") {
                AnyView(ToggleRow(label: "Transkript-Popup nach Aufnahme",
                                  desc: "Zeigt das Ergebnis kurz als Popup über der Menüleiste an.",
                                  value: Binding(
                                    get: { viewModel.showTranscript },
                                    set: { _ in viewModel.toggleShowTranscript() }
                                  ),
                                  isMock: false))
                AnyView(ToggleRow(label: "Smart punctuation",
                                  desc: "Insert commas and periods automatically based on intonation.",
                                  value: $autoPunct,
                                  isMock: true))   // TODO(smart-punct)
            }

            SettingsSection(title: "Privacy", caption: "Where your words go — and where they don't") {
                AnyView(ToggleRow(label: "Save transcripts on this Mac",
                                  desc: "Keep a local history. Disable to drop transcripts after they're typed.",
                                  value: $saveLocal,
                                  isMock: true))   // TODO(history-toggle)
                AnyView(ToggleRow(label: "Share anonymous usage data",
                                  desc: "Help improve Voicy by sending non-identifying interaction stats. No audio, ever.",
                                  value: $usage,
                                  isMock: true))   // TODO(usage-stats)
                AnyView(DangerButtonRow(label: "Delete all transcripts", isMock: true))   // TODO(history-clear)
            }

            SettingsSection(title: "Updates", caption: "When Voicy looks for new builds") {
                AnyView(RadioRow(label: "Update channel",
                                 desc: "Stable is checked daily. Beta gets the new stuff first.",
                                 value: $updates,
                                 options: [
                                    .init(id: "stable", label: "Stable", sub: "Reliable, daily check"),
                                    .init(id: "beta",   label: "Beta",   sub: "Early features, weekly"),
                                    .init(id: "manual", label: "Manual", sub: "Only when you ask"),
                                 ],
                                 isMock: true))   // TODO(update-channel)
            }

            HStack {
                MetaLabel(text: "Settings save instantly.")
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4.2"
        return v
    }
    private var releaseDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: Date())
    }
}

// MARK: - Section primitives

private struct SettingsSection<Content: View>: View {
    let title: String
    let caption: String
    let content: () -> Content

    init(title: String, caption: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DS.Font.serif(22))
                    .tracking(-0.3)
                Text(caption)
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.top, 12)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
            .dsPanel()
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ToggleRow: View {
    let label: String
    let desc: String
    @Binding var value: Bool
    let isMock: Bool

    @Environment(\.isFirstRow) private var isFirstRow

    var body: some View {
        VStack(spacing: 0) {
            if !isFirstRow { SoftDivider() }
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(DS.Font.sans(14, weight: .semibold))
                            .foregroundStyle(DS.Palette.ink)
                        if isMock { mockBadge }
                    }
                    Text(desc)
                        .font(DS.Font.sans(12))
                        .lineSpacing(2)
                        .foregroundStyle(DS.Palette.ink3)
                }
                Spacer()
                Toggle("", isOn: $value)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(DS.Palette.accent)
                    .disabled(isMock)
            }
            .padding(.vertical, 18)
        }
    }

    private var mockBadge: some View {
        Text("Demo")
            .font(DS.Font.mono(8))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(DS.Palette.ink3)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}

private struct SelectRow: View {
    let label: String
    let desc: String
    @Binding var value: String
    let options: [String]
    let isMock: Bool

    var body: some View {
        VStack(spacing: 0) {
            SoftDivider()
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(DS.Font.sans(14, weight: .semibold))
                            .foregroundStyle(DS.Palette.ink)
                        if isMock {
                            Text("Demo")
                                .font(DS.Font.mono(8))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundStyle(DS.Palette.ink3)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                        }
                    }
                    Text(desc)
                        .font(DS.Font.sans(12))
                        .lineSpacing(2)
                        .foregroundStyle(DS.Palette.ink3)
                }
                Spacer()
                Picker("", selection: $value) {
                    ForEach(options, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(minWidth: 220)
                .disabled(isMock)
            }
            .padding(.vertical, 18)
        }
    }
}

private struct SliderRow: View {
    let label: String
    let desc: String
    @Binding var value: Double
    let min: Double
    let max: Double
    let suffix: String
    let isMock: Bool

    var body: some View {
        VStack(spacing: 0) {
            SoftDivider()
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(label)
                                .font(DS.Font.sans(14, weight: .semibold))
                                .foregroundStyle(DS.Palette.ink)
                            if isMock {
                                Text("Demo")
                                    .font(DS.Font.mono(8))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundStyle(DS.Palette.ink3)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                            }
                        }
                        Text(desc)
                            .font(DS.Font.sans(12))
                            .lineSpacing(2)
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    Spacer()
                    Text("\(Int(value))\(suffix)")
                        .font(DS.Font.mono(13))
                        .foregroundStyle(DS.Palette.ink2)
                }
                Slider(value: $value, in: min...max)
                    .tint(DS.Palette.accent)
                    .disabled(isMock)
            }
            .padding(.vertical, 18)
        }
    }
}

private struct RadioRow: View {
    struct Option: Identifiable {
        let id: String
        let label: String
        let sub: String
    }

    let label: String
    let desc: String
    @Binding var value: String
    let options: [Option]
    let isMock: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(DS.Font.sans(14, weight: .semibold))
                        .foregroundStyle(DS.Palette.ink)
                    if isMock {
                        Text("Demo")
                            .font(DS.Font.mono(8))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(DS.Palette.ink3)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    }
                }
                Text(desc)
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }

            HStack(spacing: 10) {
                ForEach(options) { opt in
                    let active = value == opt.id
                    Button {
                        if !isMock { value = opt.id }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(opt.label)
                                .font(DS.Font.sans(13, weight: .semibold))
                                .foregroundStyle(active ? DS.Palette.paper : DS.Palette.ink)
                            Text(opt.sub)
                                .font(DS.Font.sans(11))
                                .foregroundStyle(active ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(active ? DS.Palette.ink : DS.Palette.paper)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(active ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 18)
    }
}

private struct DangerButtonRow: View {
    let label: String
    let isMock: Bool

    var body: some View {
        VStack(spacing: 0) {
            SoftDivider()
            HStack {
                Button(label) {}
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(12, weight: .medium))
                    .foregroundStyle(Color(red: 0.659, green: 0.200, blue: 0.122))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(Color(red: 0.659, green: 0.200, blue: 0.122).opacity(0.4), lineWidth: 1))
                    .disabled(isMock)
                if isMock {
                    Text("Demo")
                        .font(DS.Font.mono(8))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.ink3)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                }
                Spacer()
            }
            .padding(.vertical, 18)
        }
    }
}

// Helper: first-row detection via preference keys
private struct FirstRowKey: EnvironmentKey { static let defaultValue: Bool = false }
private extension EnvironmentValues {
    var isFirstRow: Bool {
        get { self[FirstRowKey.self] }
        set { self[FirstRowKey.self] = newValue }
    }
}
