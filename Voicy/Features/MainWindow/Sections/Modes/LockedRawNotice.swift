import SwiftUI

struct LockedRawNotice: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: ModeType.raw.systemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Palette.ink2)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Raw")
                    .font(DS.Font.sans(13, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
                Text("Always slot 01. Cannot be changed.")
                    .font(DS.Font.mono(9))
                    .tracking(0.4)
                    .foregroundStyle(DS.Palette.ink3)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}
