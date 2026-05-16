import SwiftUI

struct OnboardingProgressBar: View {
    let value: Double // 0…100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Palette.ink.opacity(0.1))
                Capsule()
                    .fill(DS.Palette.accent)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 100) / 100))
            }
        }
        .frame(height: 6)
    }
}
