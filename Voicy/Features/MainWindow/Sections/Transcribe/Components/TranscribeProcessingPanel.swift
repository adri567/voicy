import SwiftUI

struct TranscribeProcessingPanel: View {
    let fileMetadata: TranscribeFileInfo?
    let engineName: String
    let sourceLabel: String

    @State private var pulse: Double = 0.4
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 22)
            indeterminateWaveform
                .padding(.bottom, 18)
            ProgressView()
                .progressViewStyle(.linear)
                .tint(DS.Palette.accent)
                .padding(.bottom, 14)
            footer
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
        .dsPanel()
        .onAppear {
            guard !reduceMotion else {
                pulse = 1.0
                return
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DS.Palette.accent)
                        .frame(width: 6, height: 6)
                    MetaLabel(text: "Transcribing", color: DS.Palette.accent)
                        .font(DS.Font.mono(9))
                }
                Text(fileMetadata?.name ?? "…")
                    .font(DS.Font.serif(22))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink)
                    .lineLimit(1)
                if let meta = fileMetadata {
                    Text("\(meta.format) · \(meta.size) · \(meta.durationLabel)")
                        .font(DS.Font.mono(11))
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            Spacer(minLength: 12)
        }
    }

    @ViewBuilder
    private var indeterminateWaveform: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 2
            let minBarWidth: CGFloat = 3
            let barCount = max(24, Int((proxy.size.width + spacing) / (minBarWidth + spacing)))
            let totalSpacing = spacing * CGFloat(barCount - 1)
            let barWidth = max(minBarWidth, (proxy.size.width - totalSpacing) / CGFloat(barCount))

            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DS.Palette.accent.opacity(0.5 + pulse * 0.5))
                        .frame(width: barWidth, height: barHeight(for: i))
                }
            }
            .frame(width: proxy.size.width, height: 60, alignment: .leading)
            .opacity(pulse)
        }
        .frame(height: 60)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let phase = Double(index) * 0.34 + pulse * .pi
        let normalized = (sin(phase) * 0.5 + 0.55).clamped(0.15, 1.0)
        return CGFloat(normalized * 60)
    }

    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .center) {
            Text("\(engineName) is decoding · \(sourceLabel)")
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.ink2)
            Spacer(minLength: 12)
        }
    }
}

private extension Double {
    func clamped(_ lower: Double, _ upper: Double) -> Double {
        min(max(self, lower), upper)
    }
}
