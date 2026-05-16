import SwiftUI

struct AddSlotButton: View {
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .regular))
                Text(disabled ? "FULL" : "ADD")
                    .font(DS.Font.mono(8))
                    .tracking(1.2)
            }
            .frame(width: 72, height: 168)
            .foregroundStyle(disabled ? DS.Palette.ink3 : DS.Palette.ink2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        disabled ? DS.Palette.ink.opacity(0.10) : DS.Palette.ink.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
