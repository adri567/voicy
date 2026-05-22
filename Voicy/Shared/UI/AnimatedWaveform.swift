import SwiftUI

struct AnimatedWaveform: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var color: Color = .white
    var barCount: Int = 7
    var maxHeight: CGFloat = 44
    var level: Float = 1.0

    var body: some View {
        if reduceMotion {
            // Reduce Motion: freeze the bars to a static waveform shape so the
            // recording state is still legible without continuous motion.
            bars(t: 0)
        } else {
            TimelineView(.animation) { context in
                bars(t: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func bars(t: Double) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 4, height: barHeight(bar: i, t: t))
            }
        }
        .frame(height: maxHeight)
    }

    private func barHeight(bar: Int, t: Double) -> CGFloat {
        let freq = 2.2 + Double(bar) * 0.35
        let phase = Double(bar) * .pi / 2.5
        let sine = (sin(t * freq + phase) + 1) / 2
        let minH = maxHeight * 0.18
        let dynamicMax = minH + CGFloat(level) * (maxHeight - minH)
        return minH + CGFloat(sine) * (dynamicMax - minH)
    }
}
