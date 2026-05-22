import SwiftUI

struct EditorIconButton: View {
    let icon: String
    let label: String
    let disabled: Bool
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundStyle(disabled ? DS.Palette.ink3 : (danger ? DS.Palette.accent : DS.Palette.ink2))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(label)
    }
}
