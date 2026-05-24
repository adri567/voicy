import SwiftUI

struct OnboardingProgressBar: View {
    let phase: DownloadPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Palette.ink.opacity(0.1))
                fill(width: geo.size.width)
            }
            .clipShape(Capsule())
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private func fill(width: CGFloat) -> some View {
        if let fraction = phase.fraction {
            Capsule()
                .fill(DS.Palette.accent)
                .frame(width: width * CGFloat(min(max(fraction, 0), 1)))
        } else if reduceMotion {
            Capsule()
                .fill(DS.Palette.accent.opacity(0.5))
                .frame(width: width * 0.35)
        } else {
            let segment = width * 0.3
            TimelineView(.animation) { context in
                let cycle = (context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 1.2)) / 1.2
                Capsule()
                    .fill(DS.Palette.accent)
                    .frame(width: segment)
                    .offset(x: (width + segment) * CGFloat(cycle) - segment)
            }
        }
    }
}
