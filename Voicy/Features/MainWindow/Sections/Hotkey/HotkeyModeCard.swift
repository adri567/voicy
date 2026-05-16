import SwiftUI

struct HotkeyModeCard: View {
    let mode: HotkeyMode
    let isActive: Bool
    let isImplemented: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    MetaLabel(text: mode.subtitle, color: isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    Spacer()
                    if !isImplemented {
                        // MOCK marker
                        Text("Soon")
                            .font(DS.Font.mono(8))
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                            .overlay(Capsule().stroke(isActive ? DS.Palette.paper.opacity(0.3) : DS.Palette.ruleSoft, lineWidth: 1))
                    }
                }
                .padding(.bottom, 12)

                Text(mode.title)
                    .font(DS.Font.serif(32))
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
                    .padding(.bottom, 8)

                Text(mode.description)
                    .font(DS.Font.sans(13))
                    .lineSpacing(2)
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.75) : DS.Palette.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)

                Text(mode.gesture)
                    .font(DS.Font.mono(10))
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        isActive ? Color.white.opacity(0.06) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? Color.white.opacity(0.1) : DS.Palette.ruleSoft, lineWidth: 1)
                    )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .fill(isActive ? DS.Palette.ink : DS.Palette.paperCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .shadow(color: isActive ? .black.opacity(0.3) : .black.opacity(0.03), radius: isActive ? 24 : 2, y: isActive ? 12 : 1)
        }
        .buttonStyle(.plain)
    }
}
