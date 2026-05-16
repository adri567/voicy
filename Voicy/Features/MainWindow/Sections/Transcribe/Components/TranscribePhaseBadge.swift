import SwiftUI

struct TranscribePhaseBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(DS.Font.mono(8, weight: .medium))
            .textCase(.uppercase)
            .tracking(1.4)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(DS.Palette.accent)
            .background(DS.Palette.accent.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(DS.Palette.accent.opacity(0.25), lineWidth: 1))
    }
}
