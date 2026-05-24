import SwiftUI

/// Schmaler Progress-Bar für laufende Downloads. Renders a determinate fill for
/// `.downloading`, and an indeterminate sliding bar with a label for the
/// `.preparing`/`.finalizing` phases (which carry no measurable fraction).
struct ProgressBar: View {
    let phase: DownloadPhase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 6)
                    fill(width: geo.size.width)
                }
                .clipShape(Capsule())
            }
            .frame(height: 6)
            Text(phase.shortLabel)
                .font(DS.Font.mono(9))
                .foregroundStyle(DS.Palette.ink3)
        }
    }

    @ViewBuilder
    private func fill(width: CGFloat) -> some View {
        if let fraction = phase.fraction {
            Capsule()
                .fill(DS.Palette.accent)
                .frame(width: width * CGFloat(max(0, min(fraction, 1))), height: 6)
        } else if reduceMotion {
            // No continuous motion: a fixed partial fill still reads as "busy".
            Capsule()
                .fill(DS.Palette.accent.opacity(0.5))
                .frame(width: width * 0.35, height: 6)
        } else {
            indeterminate(trackWidth: width)
        }
    }

    /// A short segment sliding left→right across the track.
    private func indeterminate(trackWidth: CGFloat) -> some View {
        let segment = trackWidth * 0.3
        return TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cycle = (t.truncatingRemainder(dividingBy: 1.2)) / 1.2 // 0…1 over 1.2s
            let offset = (trackWidth + segment) * CGFloat(cycle) - segment
            Capsule()
                .fill(DS.Palette.accent)
                .frame(width: segment, height: 6)
                .offset(x: offset)
        }
    }
}
