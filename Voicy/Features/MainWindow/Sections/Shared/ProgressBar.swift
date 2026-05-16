import SwiftUI

/// Schmaler Progress-Bar für laufende Downloads.
struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(DS.Palette.accent)
                        .frame(width: geo.size.width * max(0, min(fraction, 1)), height: 6)
                }
            }
            .frame(height: 6)
            Text("\(Int((max(0, min(fraction, 1))) * 100))%")
                .font(DS.Font.mono(9))
                .foregroundStyle(DS.Palette.ink3)
        }
    }
}
