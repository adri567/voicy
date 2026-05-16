import SwiftUI

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.sans(13, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .overlay(
                    Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
