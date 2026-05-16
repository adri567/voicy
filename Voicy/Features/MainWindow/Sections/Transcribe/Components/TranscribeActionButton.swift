import SwiftUI

struct TranscribeActionButton: View {
    let title: String
    var flash: Bool = false
    var disabled: Bool = false
    var trailing: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                if let trailing {
                    TranscribePhaseBadge(label: trailing)
                }
            }
            .font(DS.Font.mono(10, weight: .medium))
            .textCase(.uppercase)
            .tracking(1.0)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(background, in: Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var foreground: Color {
        flash ? DS.Palette.accentInk : DS.Palette.ink2
    }
    private var background: Color {
        flash ? DS.Palette.accent : .clear
    }
    private var border: Color {
        flash ? DS.Palette.accent : DS.Palette.ruleSoft
    }
}
