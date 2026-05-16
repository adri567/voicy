import SwiftUI

struct BrainFilterChip: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(DS.Font.mono(10))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? DS.Palette.ink : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
