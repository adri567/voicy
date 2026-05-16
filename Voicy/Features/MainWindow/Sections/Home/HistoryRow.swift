import AppKit
import SwiftUI

struct HistoryRow: View {
    let entry: TranscriptionEntry
    let first: Bool

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
        }
        .contextMenu {
            Button("Kopieren") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.text, forType: .string)
            }
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
