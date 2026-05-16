import SwiftUI

struct LocationChip: View {
    let location: LLMModel.Location

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
            Text(location == .cloud ? "Cloud" : "Local")
                .font(DS.Font.mono(9))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(background, in: Capsule())
        .overlay(Capsule().stroke(border, lineWidth: 1))
    }

    private var dotColor: Color {
        location == .cloud ? DS.Palette.accent2 : DS.Palette.ink2
    }
    private var textColor: Color {
        location == .cloud ? DS.Palette.accent2 : DS.Palette.ink2
    }
    private var background: Color {
        location == .cloud ? DS.Palette.accent2.opacity(0.10) : Color.black.opacity(0.05)
    }
    private var border: Color {
        location == .cloud ? DS.Palette.accent2.opacity(0.18) : DS.Palette.ruleSoft
    }
}
