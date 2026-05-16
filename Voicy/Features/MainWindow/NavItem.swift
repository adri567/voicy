import SwiftUI

struct NavItem: View {
    let section: SidebarSection
    let isActive: Bool
    let isCompact: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            if isCompact {
                Image(systemName: section.systemImage)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 36)
                    .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.small))
                    .contentShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    .help(section.label)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(iconColor)
                        .frame(width: 18, height: 18)

                    Text(section.label)
                        .font(DS.Font.sans(14, weight: .medium))
                        .foregroundStyle(labelColor)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.small))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.small))
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var iconColor: Color {
        if isActive { return DS.Palette.accent }
        return DS.Palette.ink3
    }

    private var labelColor: Color {
        if isActive { return DS.Palette.ink }
        if isHovering { return DS.Palette.ink }
        return DS.Palette.ink2
    }

    private var background: Color {
        if isActive { return Color.black.opacity(0.08) }
        if isHovering { return Color.black.opacity(0.04) }
        return .clear
    }
}
