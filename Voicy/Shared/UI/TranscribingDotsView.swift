import SwiftUI

struct TranscribingDotsView: View {
    var color: Color = .white

    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                        .scaleEffect(scale(index: i, t: context.date.timeIntervalSinceReferenceDate))
                        .opacity(opacity(index: i, t: context.date.timeIntervalSinceReferenceDate))
                }
            }
        }
    }

    private func scale(index: Int, t: Double) -> CGFloat {
        let period = 0.9
        let delay = Double(index) * 0.3
        let phase = (t - delay).truncatingRemainder(dividingBy: period) / period
        return 0.5 + CGFloat(max(0, sin(phase * .pi))) * 1.0
    }

    private func opacity(index: Int, t: Double) -> Double {
        let period = 0.9
        let delay = Double(index) * 0.3
        let phase = (t - delay).truncatingRemainder(dividingBy: period) / period
        return 0.3 + max(0, sin(phase * .pi)) * 0.7
    }
}
