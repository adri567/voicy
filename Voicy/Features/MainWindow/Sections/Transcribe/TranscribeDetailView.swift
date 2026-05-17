import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Full-reader sub-view for one `FileTranscriptionEntry`. Reached by clicking
/// the PreviewCard (latest) or any HistoryRow. Audio playback is intentionally
/// not wired here — we don't persist file URLs across app launches.
struct TranscribeDetailView: View {

    let entry: FileTranscriptionEntry
    let onBack: () -> Void

    @State private var continuous = true
    @State private var showSpeakers = false
    @State private var showTime = true
    @State private var showPunctuation = true
    @State private var copied = false
    @State private var copiedResetTask: Task<Void, Never>?

    private var speakersAvailable: Bool {
        entry.segments.contains { $0.speaker != nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.bottom, 28)
                fileHeader
                    .padding(.bottom, 22)
                TranscribeDetailToggles(
                    continuous: $continuous,
                    showSpeakers: $showSpeakers,
                    showTime: $showTime,
                    showPunctuation: $showPunctuation,
                    speakersAvailable: speakersAvailable
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
        if continuous {
            continuousPanel
        } else {
            segmentsPanel
        }
    }

    @ViewBuilder
    private var segmentsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entry.segments.enumerated(), id: \.element.id) { index, segment in
                TranscribeSegmentRow(
                    segment: segment,
                    isFirst: index == 0,
                    showTime: showTime,
                    showPunctuation: showPunctuation,
                    showSpeaker: showSpeakers && speakersAvailable,
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
    private var continuousPanel: some View {
        if showSpeakers && speakersAvailable {
            speakerGroupedContinuousPanel
        } else {
            Text(continuousText)
                .font(DS.Font.serif(18))
                .foregroundStyle(DS.Palette.ink)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .padding(.horizontal, 30)
                .padding(.vertical, 26)
                .dsPanel()
        }
    }

    @ViewBuilder
    private var speakerGroupedContinuousPanel: some View {
        let groups = speakerGroups
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speaker \((group.speaker ?? 0) + 1)")
                        .dsTag(accent: true)
                    Text(group.text)
                        .font(DS.Font.serif(18))
                        .foregroundStyle(DS.Palette.ink)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 26)
        .dsPanel()
    }

    /// Group consecutive segments by their speaker so the continuous view
    /// reads like a conversation transcript ("Speaker 1: … Speaker 2: …").
    private var speakerGroups: [(speaker: Int?, text: String)] {
        var groups: [(speaker: Int?, text: String)] = []
        for seg in entry.segments {
            let cleaned = formatted(seg.text)
            guard !cleaned.isEmpty else { continue }
            if let last = groups.last, last.speaker == seg.speaker {
                groups[groups.count - 1].text = last.text + " " + cleaned
            } else {
                groups.append((seg.speaker, cleaned))
            }
        }
        return groups
    }

    private var continuousText: String {
        // Prefer the aggregated `fullText` over `segments.map(\.text).joined()`.
        // WhisperKit's `TranscriptionResult.text` is the post-processed
        // aggregate (casing + punctuation re-applied), while the per-segment
        // texts are the raw model output and are often lowercase / unpunctuated.
        let raw = entry.fullText.isEmpty
            ? entry.segments.map(\.text).joined(separator: " ")
            : entry.fullText
        return formatted(raw)
    }

    private func formatted(_ raw: String) -> String {
        guard !showPunctuation else { return raw }
        let scalars = raw.lowercased().unicodeScalars.filter { scalar in
            !CharacterSet(charactersIn: ".,!?;:—").contains(scalar)
        }
        return String(String.UnicodeScalarView(scalars))
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
