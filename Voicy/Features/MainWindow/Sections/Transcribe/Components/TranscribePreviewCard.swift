import AppKit
import SwiftUI

/// Compact "latest run" teaser. Replaces the old inline segment list on the
/// Transcribe main page; clicking the card opens the full TranscriptDetail.
struct TranscribePreviewCard: View {
    let fileName: String
    let durationLabel: String
    let sourceCode: String
    let words: Int
    let segmentCount: Int
    let segments: [TranscriptionSegment]
    let onOpen: () -> Void

    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            preview
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.panel)
                .stroke(DS.Palette.ruleSoft, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if copied {
                Text("Kopiert")
                    .font(DS.Font.mono(9, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(DS.Palette.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DS.Palette.accent.opacity(0.12), in: Capsule())
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                    .transition(.opacity)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.panel))
        .gesture(
            TapGesture(count: 2)
                .onEnded { copyText() }
                .exclusively(before:
                    TapGesture(count: 1).onEnded { onOpen() }
                )
        )
        .contextMenu {
            Button("Vollständigen Text kopieren") { copyText() }
            Button("Detail öffnen") { onOpen() }
        }
    }

    private func copyText() {
        let text = segments.map(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) { copied = true }
        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { copied = false }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                tagRow
                Text(fileName)
                    .font(DS.Font.serif(24))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 12)
            wordCount
        }
    }

    @ViewBuilder
    private var tagRow: some View {
        HStack(spacing: 6) {
            Text("Latest").dsTag(accent: true)
            Text(sourceCode.uppercased()).dsTag()
            Text(durationLabel).dsTag()
        }
    }

    @ViewBuilder
    private var wordCount: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(words)")
                .font(DS.Font.serif(30))
                .monospacedDigit()
                .foregroundStyle(DS.Palette.ink)
            MetaLabel(text: "words · \(segmentCount) segments")
                .font(DS.Font.mono(8))
        }
    }

    @ViewBuilder
    private var preview: some View {
        HStack(alignment: .bottom, spacing: 24) {
            previewParagraph
                .frame(maxWidth: .infinity, alignment: .leading)
            openButton
        }
    }

    @ViewBuilder
    private var previewParagraph: some View {
        let firstText = segments.first?.text ?? ""
        let secondText = segments.dropFirst().first?.text
        let primary = Text(firstText).foregroundStyle(DS.Palette.ink2)
        let secondary = secondText.map {
            Text(" \($0)").foregroundStyle(DS.Palette.ink3)
        } ?? Text("")

        Text("\(primary)\(secondary)")
            .font(DS.Font.sans(15))
            .lineSpacing(4)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var openButton: some View {
        HStack(spacing: 8) {
            Text("Open transcript")
                .font(DS.Font.sans(12, weight: .semibold))
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(DS.Palette.paper)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DS.Palette.ink, in: Capsule())
    }
}
