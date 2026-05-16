import SwiftUI

struct TranscribeSegmentRow: View {
    let segment: TranscriptionSegment
    let isFirst: Bool
    var showTime: Bool = true
    var showPunctuation: Bool = true
    var currentlyPlaying: Bool = false
    var onJump: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst {
                SoftDivider()
            }
            Button(action: onJump) {
                HStack(alignment: .top, spacing: 24) {
                    leadingColumn
                        .frame(width: 110, alignment: .leading)
                    textColumn
                        .frame(maxWidth: .infinity, alignment: .leading)
                    wordCountColumn
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .leading) {
            if currentlyPlaying {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.Palette.accent)
                    .frame(width: 4)
                    .padding(.vertical, 18)
                    .offset(x: -18)
            }
        }
    }

    @ViewBuilder
    private var leadingColumn: some View {
        if showTime {
            VStack(alignment: .leading, spacing: 6) {
                Text(formatted(segment.start))
                    .font(DS.Font.mono(15, weight: .medium))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink2)
                Text("→ \(formatted(segment.end))")
                    .font(DS.Font.mono(8))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(DS.Palette.ink3)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var textColumn: some View {
        Text(displayText)
            .font(DS.Font.sans(15))
            .foregroundStyle(DS.Palette.ink)
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var wordCountColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(wordCount)")
                .font(DS.Font.serif(22))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink3)
            MetaLabel(text: "words")
                .font(DS.Font.mono(8))
        }
    }

    private var displayText: String {
        guard !showPunctuation else { return segment.text }
        let scalars = segment.text.lowercased().unicodeScalars.filter { scalar in
            !CharacterSet(charactersIn: ".,!?;:—").contains(scalar)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    private var wordCount: Int {
        segment.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func formatted(_ time: TimeInterval) -> String {
        Duration.seconds(Int(time)).formatted(.time(pattern: .minuteSecond))
    }
}
