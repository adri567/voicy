import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Full-reader sub-view for one `FileTranscriptionEntry`. Reached by clicking
/// the PreviewCard (latest) or any HistoryRow. Audio playback is intentionally
/// not wired here — we don't persist file URLs across app launches.
struct TranscribeDetailView: View {

    let entry: FileTranscriptionEntry
    let onBack: () -> Void

    @State private var showTime = true
    @State private var showPunctuation = true
    @State private var copied = false
    @State private var copiedResetTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.bottom, 28)
                fileHeader
                    .padding(.bottom, 22)
                TranscribeDetailToggles(
                    showTime: $showTime,
                    showPunctuation: $showPunctuation
                )
                .padding(.bottom, 22)
                actionsRow
                    .padding(.bottom, 22)
                transcriptPanel
                footerMeta
                    .padding(.top, 18)
                    .padding(.bottom, 56)
            }
            .padding(.horizontal, DS.Spacing.pageHPadding)
            .padding(.top, DS.Spacing.pageTop)
        }
        .background(DS.Palette.paper)
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back to transcribe")
                        .font(DS.Font.mono(10, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .foregroundStyle(DS.Palette.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.clear, in: Capsule())
                .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to transcribe")
            Spacer()
        }
    }

    // MARK: - File header

    @ViewBuilder
    private var fileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(entry.engine == .whisper ? "WHISPER" : "PARAKEET").dsTag()
                Text(entry.sourceLanguageCode.uppercased()).dsTag()
                Text(entry.durationLabel).dsTag()
                Text("\(entry.wordCount) words").dsTag()
            }
            Text(entry.fileName)
                .font(DS.Font.serif(42))
                .tracking(-0.5)
                .foregroundStyle(DS.Palette.ink)
                .lineLimit(2)
                .truncationMode(.middle)
            Text(entry.fileFormat)
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.ink3)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionsRow: some View {
        HStack(spacing: 8) {
            TranscribeActionButton(
                title: copied ? "✓ Copied" : "Copy all",
                flash: copied,
                action: copyAll
            )
            TranscribeActionButton(title: "Download .txt", action: downloadTxt)
        }
    }

    // MARK: - Transcript

    @ViewBuilder
    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entry.segments.enumerated(), id: \.element.id) { index, segment in
                TranscribeSegmentRow(
                    segment: segment,
                    isFirst: index == 0,
                    showTime: showTime,
                    showPunctuation: showPunctuation,
                    currentlyPlaying: false,
                    onJump: {}
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsPanel()
    }

    @ViewBuilder
    private var footerMeta: some View {
        HStack(alignment: .firstTextBaseline) {
            MetaLabel(text: "\(entry.segments.count) segments · \(entry.wordCount.formatted()) words")
                .font(DS.Font.mono(9))
            Spacer(minLength: 12)
            MetaLabel(text: "Originals stay on your Mac — never uploaded.")
                .font(DS.Font.mono(9))
        }
    }

    // MARK: - Actions impl

    private func copyAll() {
        let text = entry.segments.map(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        copiedResetTask?.cancel()
        copiedResetTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            copied = false
        }
    }

    private func downloadTxt() {
        let text = entry.segments.map(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        let panel = NSSavePanel()
        let baseName = entry.fileName
            .replacing(".m4a", with: "")
            .replacing(".mp3", with: "")
            .replacing(".wav", with: "")
            .replacing(".mp4", with: "")
        panel.nameFieldStringValue = "\(baseName).txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
