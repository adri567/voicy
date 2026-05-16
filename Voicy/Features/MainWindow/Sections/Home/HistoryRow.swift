import AppKit
import SwiftUI

struct HistoryRow: View {
    let entry: TranscriptionEntry
    let first: Bool

    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(timeString)
                        .font(DS.Font.mono(18, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(DS.Palette.ink2)
                    HStack(spacing: 6) {
                        Text(entry.engine.shortLabel).dsTag()
                        Text(durationString).dsTag()
                    }
                }
                .frame(width: 140, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    metaLine
                    Text(entry.text)
                        .font(DS.Font.sans(15))
                        .foregroundStyle(DS.Palette.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(wordCount)")
                        .font(DS.Font.serif(26))
                        .tracking(-0.2)
                        .foregroundStyle(DS.Palette.ink3)
                    MetaLabel(text: "words")
                }
                .frame(width: 90, alignment: .trailing)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { copyText() }
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
                        .padding(.top, 12)
                        .transition(.opacity)
                }
            }
        }
        .contextMenu {
            Button("Kopieren") { copyText() }
        }
    }

    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) { copied = true }
        copyResetTask?.cancel()
        copyResetTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { copied = false }
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        if let appName = entry.targetAppName {
            HStack(spacing: 8) {
                Text("→")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.accent)
                Text(appName)
                    .font(DS.Font.mono(10, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(DS.Palette.ink2)
                if let title = entry.targetWindowTitle, !title.isEmpty {
                    Text("·")
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                    Text(title)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        } else {
            MetaLabel(text: "Engine · \(entry.engine.displayName)")
        }
    }

    private var timeString: String {
        Self.timeFormatter.string(from: entry.createdAt)
    }

    private var durationString: String {
        let total = Int(entry.duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var wordCount: Int {
        entry.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}

extension TranscriptionEngine {
    var shortLabel: String {
        switch self {
        case .whisper:  "WHISPER"
        case .parakeet: "PARAKEET"
        }
    }
}
