import FactoryKit
import OSLog
import SwiftUI

struct SettingsView: View {

    var viewModel: RecordingViewModel
    @Bindable var cycle: ModeCycleService

    @AppStorage(Preferences.Key.onboardingClickSounds) private var clickSounds = true

    @State private var showingClearMicConfirmation = false
    @State private var showingClearFileConfirmation = false

    @Environment(\.openURL) private var openURL

    @Injected(\.transcriptionHistoryService) private var micHistoryService
    @Injected(\.fileTranscriptionHistoryService) private var fileHistoryService
    @Injected(\.updateService) private var updateService

    private let releaseNotesURL = URL(string: "https://github.com/adri567/voicy/releases")!

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
                Log.settings.error("Mic history deleteAll failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func clearFileHistory() {
        Task { [fileHistoryService] in
            do {
                try await fileHistoryService.deleteAll()
            } catch {
                Log.settings.error("File history deleteAll failed: \(error.localizedDescription, privacy: .public)")
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
                    .frame(maxWidth: 460, alignment: .leading)
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
                aboutButton("Check for updates", filled: true) { updateService.checkForUpdates() }
                aboutButton("Release notes", filled: false) { openURL(releaseNotesURL) }
            }
        }
        .padding(26)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
    }

    private func aboutButton(_ label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
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

            SettingsSection(title: "General", caption: "Small comforts while Voicy runs") {
                SettingsToggleRow(label: "Play a sound on start / stop",
                                  desc: "A soft click when dictation begins and ends.",
                                  value: $clickSounds,
                                  isMock: false)
            }

            SettingsSection(title: "Language", caption: "What you speak — and what Voicy listens for") {
                SettingsLanguageRow(cycle: cycle)
            }

            SettingsSection(title: "Transcription", caption: "Defaults the engine uses") {
                SettingsToggleRow(label: "Transcript popup after recording",
                                  desc: "Briefly shows the result as a popup above the menu bar.",
                                  value: Binding(
                                    get: { viewModel.showTranscript },
                                    set: { _ in viewModel.toggleShowTranscript() }
                                  ),
                                  isMock: false)
            }

            SettingsSection(title: "Privacy", caption: "Where your words go — and where they don't") {
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

            SettingsSection(title: "Onboarding", caption: "Replay the first-run tour any time you like") {
                OnboardingResetRow()
            }

            ColophonSection()

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
