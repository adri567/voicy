import SwiftUI

/// Sekundärer Trash-Button für Model-Rows in EngineView/BrainView.
struct TrashButton: View {
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .regular))
                Text("Remove")
                    .font(DS.Font.sans(11, weight: .medium))
            }
            .foregroundStyle(isHovering ? DS.Palette.ink : DS.Palette.ink3)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                Capsule().stroke(
                    isHovering ? DS.Palette.ink : DS.Palette.ruleSoft,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
