import SwiftUI

struct TranscribeFilterChip: View {
    let label: String
    let isActive: Bool
    var disabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button {
            guard !disabled else { return }
            onTap()
        } label: {
            Text(label)
                .font(DS.Font.mono(10, weight: .medium))
                .textCase(.uppercase)
                .tracking(1.0)
                .foregroundStyle(foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(background, in: Capsule())
                .overlay(Capsule().stroke(border, lineWidth: 1))
                .opacity(disabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var foreground: Color {
        isActive ? DS.Palette.paper : DS.Palette.ink2
    }

    private var background: Color {
        isActive ? DS.Palette.ink : .clear
    }

    private var border: Color {
        isActive ? DS.Palette.ink : DS.Palette.ruleSoft
    }
}
