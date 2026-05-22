import SwiftUI

struct MicrophoneRow: View {
    let device: AudioInputDevice
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                AudioDeviceKindIcon(kind: device.kind, size: 10)
                    .frame(width: 16, alignment: .center)
                    .foregroundStyle(isActive ? DS.Palette.accent : DS.Palette.ink3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(DS.Font.sans(13, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(device.subtitle)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var rowBackground: Color {
        if isActive { return DS.Palette.accent.opacity(0.06) }
        if isHovered { return DS.Palette.paper2 }
        return .clear
    }
}
