import SwiftUI

struct PrimaryButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.sans(13, weight: .semibold))
                .foregroundStyle(disabled ? DS.Palette.ink.opacity(0.5) : DS.Palette.paper)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(
                    Capsule().fill(disabled ? DS.Palette.ink.opacity(0.18) : DS.Palette.ink)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
