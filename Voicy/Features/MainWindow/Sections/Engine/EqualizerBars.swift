import SwiftUI

struct EqualizerBars: View {
    private let heights: [Double] = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.8, 0.5, 0.6, 0.4, 0.7, 0.5, 0.3, 0.9, 0.6]

    var body: some View {
        TimelineView(.animation) { ctx in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<heights.count, id: \.self) { i in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let delay = Double(i) * 0.08
                    let speed = 1.0 + Double(i % 4) * 0.2
                    let phase = (t / speed + delay).truncatingRemainder(dividingBy: 1)
                    let amplitude = 0.3 + abs(sin(phase * .pi)) * 0.7
                    Capsule()
                        .fill(DS.Palette.paper)
                        .frame(width: 3, height: 24 * heights[i] * amplitude)
                }
            }
        }
    }
}
