import FactoryKit
import SwiftUI

struct SettingsView: View {

    var viewModel: RecordingViewModel
    @Bindable var cycle: ModeCycleService

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

    @State private var showingClearMicConfirmation = false
    @State private var showingClearFileConfirmation = false

    @Injected(\.transcriptionHistoryService) private var micHistoryService
    @Injected(\.fileTranscriptionHistoryService) private var fileHistoryService

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
        .alert("Clear Home history?", isPresented: $showingClearMicConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { clearMicHistory() }
        } message: {
            Text("All mic recordings will be permanently removed from Home history.")
        }
        .alert("Clear Transcribe history?", isPresented: $showingClearFileConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { clearFileHistory() }
        } message: {
            Text("All file transcriptions will be permanently removed from Transcribe history.")
        }
    }

    private func clearMicHistory() {
        Task { [micHistoryService] in
            do {
                try await micHistoryService.deleteAll()
            } catch {
                print("[Settings] Mic history deleteAll failed: \(error.localizedDescription)")
            }
        }
    }

    private func clearFileHistory() {
        Task { [fileHistoryService] in
            do {
                try await fileHistoryService.deleteAll()
            } catch {
                print("[Settings] File history deleteAll failed: \(error.localizedDescription)")
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
                SettingsToggleRow(label: "Launch at login",
                                  desc: "Have Voicy start automatically when you sign in.",
                                  value: $launchAtLogin,
                                  isMock: true)   // TODO(launch-at-login)
                SettingsToggleRow(label: "Show menu bar icon",
                                  desc: "A small waveform in the menu bar — click for quick controls.",
                                  value: $menuBarIcon,
                                  isMock: true)   // TODO(menubar-toggle)
                SettingsToggleRow(label: "Play a sound on start / stop",
                                  desc: "A soft click when dictation begins and ends.",
                                  value: $soundOnStart,
                                  isMock: true)   // TODO(sound-toggle)
            }

            SettingsSection(title: "Language", caption: "What you speak — and what Voicy listens for") {
                SettingsLanguageRow(cycle: cycle)
            }

            SettingsSection(title: "Audio", caption: "The microphone and how Voicy listens") {
                SettingsSelectRow(label: "Input device",
                                  desc: "Pick which microphone Voicy listens to.",
                                  value: $device,
                                  options: ["MacBook Pro Microphone", "Studio Display Microphone", "AirPods Pro (2)"],
                                  isMock: true)   // TODO(audio-input)
                SettingsSliderRow(label: "Trigger sensitivity",
                                  desc: "How quickly Voicy starts capturing once you hold the key.",
                                  value: $sensitivity, min: 0, max: 100, suffix: "%",
                                  isMock: true)   // TODO(sensitivity)
            }

            SettingsSection(title: "Transcription", caption: "Defaults the engine uses") {
                SettingsToggleRow(label: "Transcript popup after recording",
                                  desc: "Briefly shows the result as a popup above the menu bar.",
                                  value: Binding(
                                    get: { viewModel.showTranscript },
                                    set: { _ in viewModel.toggleShowTranscript() }
                                  ),
                                  isMock: false)
                SettingsToggleRow(label: "Smart punctuation",
                                  desc: "Insert commas and periods automatically based on intonation.",
                                  value: $autoPunct,
                                  isMock: true)   // TODO(smart-punct)
            }

            SettingsSection(title: "Privacy", caption: "Where your words go — and where they don't") {
                SettingsToggleRow(label: "Save transcripts on this Mac",
                                  desc: "Keep a local history. Disable to drop transcripts after they're typed.",
                                  value: $saveLocal,
                                  isMock: true)   // TODO(history-toggle)
                SettingsToggleRow(label: "Share anonymous usage data",
                                  desc: "Help improve Voicy by sending non-identifying interaction stats. No audio, ever.",
                                  value: $usage,
                                  isMock: true)   // TODO(usage-stats)
                SettingsDangerButtonRow(
                    label: "Clear Home history",
                    description: "Removes all mic recordings from Home history.",
                    action: { showingClearMicConfirmation = true }
                )
                SettingsDangerButtonRow(
                    label: "Clear Transcribe history",
                    description: "Removes all file transcriptions from Transcribe history.",
                    action: { showingClearFileConfirmation = true }
                )
            }

            SettingsSection(title: "Updates", caption: "When Voicy looks for new builds") {
                SettingsRadioRow(label: "Update channel",
                                 desc: "Stable is checked daily. Beta gets the new stuff first.",
                                 value: $updates,
                                 options: [
                                    .init(id: "stable", label: "Stable", sub: "Reliable, daily check"),
                                    .init(id: "beta",   label: "Beta",   sub: "Early features, weekly"),
                                    .init(id: "manual", label: "Manual", sub: "Only when you ask"),
                                 ],
                                 isMock: true)   // TODO(update-channel)
            }

            SettingsSection(title: "Onboarding", caption: "Replay the first-run tour any time you like") {
                OnboardingResetRow()
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
