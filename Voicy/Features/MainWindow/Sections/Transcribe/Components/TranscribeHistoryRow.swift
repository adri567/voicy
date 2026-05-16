import AppKit
import SwiftUI

struct TranscribeHistoryRow: View {
    let entry: FileTranscriptionEntry
    let isFirst: Bool
    let onOpen: () -> Void

    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.doesRelativeDateFormatting = true
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                leftColumn
                    .frame(width: 140, alignment: .leading)
                middleColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
                rightColumn
                    .frame(width: 110, alignment: .trailing)
            }
            .padding(.vertical, 20)
            .contentShape(Rectangle())
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
                        .padding(.top, 16)
                        .transition(.opacity)
                }
            }
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
    }

    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.fullText, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) { copied = true }
        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { copied = false }
        }
    }

    @ViewBuilder
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeString)
                .font(DS.Font.mono(16, weight: .medium))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink2)
            Text(dateString)
                .font(DS.Font.serifItalic(13))
                .foregroundStyle(DS.Palette.ink3)
                .padding(.bottom, 6)
            HStack(spacing: 6) {
                Text(entry.sourceLanguageCode.uppercased()).dsTag()
                Text(entry.durationLabel).dsTag()
            }
        }
    }

    @ViewBuilder
    private var middleColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.fileName)
                .font(DS.Font.serif(18))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(entry.preview)
                .font(DS.Font.sans(14))
                .foregroundStyle(DS.Palette.ink2)
                .lineSpacing(3)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.wordCount)")
                    .font(DS.Font.serif(24))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink3)
                MetaLabel(text: "words")
                    .font(DS.Font.mono(8))
            }
            chevronBadge
        }
    }

    private var chevronBadge: some View {
        ZStack {
            Circle()
                .stroke(DS.Palette.ruleSoft, lineWidth: 1)
                .frame(width: 28, height: 28)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Palette.ink2)
        }
        .accessibilityHidden(true)
    }

    private var timeString: String {
        Self.timeFormatter.string(from: entry.createdAt)
    }

    private var dateString: String {
        Self.dateFormatter.string(from: entry.createdAt)
    }
}
