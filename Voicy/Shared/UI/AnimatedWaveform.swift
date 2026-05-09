import SwiftUI

struct AnimatedWaveform: View {

    var color: Color = .red
    var barCount: Int = 7
    var maxHeight: CGFloat = 44

    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule()
                        .fill(color)
                        .frame(width: 4, height: barHeight(bar: i, t: context.date.timeIntervalSinceReferenceDate))
                }
            }
            .frame(height: maxHeight)
        }
    }

    private func barHeight(bar: Int, t: Double) -> CGFloat {
        let freq = 2.2 + Double(bar) * 0.35
        let phase = Double(bar) * .pi / 2.5
        let sine = sin(t * freq + phase)
        let minH = maxHeight * 0.18
        return minH + CGFloat((sine + 1) / 2) * (maxHeight - minH)
    }
}
