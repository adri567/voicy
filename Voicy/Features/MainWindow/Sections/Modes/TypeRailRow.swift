import SwiftUI

struct TypeRailRow: View {
    let type: ModeType
    let isOn: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isOn ? DS.Palette.paper : DS.Palette.ink2)
                    .frame(width: 22, height: 22, alignment: .center)
                Text(type.label)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(isOn ? DS.Palette.paper : DS.Palette.ink2)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isOn ? DS.Palette.ink :
                (isHovering ? DS.Palette.ink.opacity(0.05) : .clear),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? DS.Palette.ink : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
