import SwiftUI

struct TranscribeFilePlayer: View {
    let fileMetadata: TranscribeFileInfo
    let waveformBars: [Double]
    let playhead: Double
    let playing: Bool
    let sourceLabel: String
    let onTogglePlay: () -> Void
    let onSeek: (Double) -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 18)
            waveformTrack
                .padding(.bottom, 12)
            footer
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .dsPanel()
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            playButton
            VStack(alignment: .leading, spacing: 4) {
                Text(fileMetadata.name)
                    .font(DS.Font.serif(22))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(fileMetadata.format) · \(fileMetadata.size) · \(fileMetadata.durationLabel)")
                    .font(DS.Font.mono(11))
                    .foregroundStyle(DS.Palette.ink3)
            }
            Spacer(minLength: 12)
            replaceButton
        }
    }

    private var playButton: some View {
        Button(action: onTogglePlay) {
            ZStack {
                Circle()
                    .fill(DS.Palette.ink)
                    .frame(width: 52, height: 52)
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Palette.paper)
                    .offset(x: playing ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playing ? "Pause" : "Play")
    }

    private var replaceButton: some View {
        Button(action: onReset) {
            Text("Replace")
                .font(DS.Font.mono(10, weight: .medium))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(DS.Palette.ink3)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DS.Palette.ruleSoft, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Remove and start over")
    }

    @ViewBuilder
    private var waveformTrack: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                waveformBarRow(width: proxy.size.width)
                Rectangle()
                    .fill(DS.Palette.accent)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .shadow(color: DS.Palette.accent.opacity(0.15), radius: 3)
                    .offset(x: proxy.size.width * playhead)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = min(max(value.location.x / proxy.size.width, 0), 1)
                        onSeek(fraction)
                    }
            )
        }
        .frame(height: 70)
    }

    @ViewBuilder
    private func waveformBarRow(width: CGFloat) -> some View {
        let bars = waveformBars.isEmpty ? TranscribeProceduralWaveform.bars : waveformBars
        let spacing: CGFloat = 2
        let totalSpacing = spacing * CGFloat(max(0, bars.count - 1))
        let barWidth = max(2, (width - totalSpacing) / CGFloat(max(1, bars.count)))

        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(bars.enumerated()), id: \.offset) { idx, value in
                let passed = Double(idx) / Double(bars.count) < playhead
                RoundedRectangle(cornerRadius: 2)
                    .fill(passed ? DS.Palette.accent : DS.Palette.ink.opacity(0.22))
                    .frame(width: barWidth, height: max(2, CGFloat(value) * 70))
            }
        }
        .frame(width: width, height: 70)
    }

    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .center) {
            timeDisplay
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                sourceTag
                Text("Ready").dsTag(solid: true)
            }
        }
    }

    @ViewBuilder
    private var timeDisplay: some View {
        let current = Text(formatted(seconds: currentSeconds))
            .foregroundStyle(DS.Palette.ink2)
        let total = Text("  / \(fileMetadata.durationLabel)")
            .foregroundStyle(DS.Palette.ink3)
        Text("\(current)\(total)")
            .font(DS.Font.mono(12, weight: .medium))
            .monospacedDigit()
    }

    private var sourceTag: some View {
        Text("Source · \(sourceLabel)")
            .font(DS.Font.mono(9, weight: .medium))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(DS.Palette.accent)
            .background(.clear, in: Capsule())
            .overlay(Capsule().stroke(DS.Palette.accent.opacity(0.3), lineWidth: 1))
    }

    private var currentSeconds: Int {
        Int(Double(fileMetadata.durationSeconds) * playhead)
    }

    private func formatted(seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}
