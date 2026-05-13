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

/// Schmaler Progress-Bar für laufende Downloads.
struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(DS.Palette.accent)
                        .frame(width: geo.size.width * max(0, min(fraction, 1)), height: 6)
                }
            }
            .frame(height: 6)
            Text("\(Int((max(0, min(fraction, 1))) * 100))%")
                .font(DS.Font.mono(9))
                .foregroundStyle(DS.Palette.ink3)
        }
    }
}
