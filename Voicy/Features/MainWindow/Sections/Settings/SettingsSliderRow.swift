import SwiftUI

struct SettingsSliderRow: View {
    let label: String
    let desc: String
    @Binding var value: Double
    let min: Double
    let max: Double
    let suffix: String
    let isMock: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(label)
                            .font(DS.Font.sans(14, weight: .semibold))
                            .foregroundStyle(DS.Palette.ink)
                        if isMock { SettingsMockBadge() }
                    }
                    Text(desc)
                        .font(DS.Font.sans(12))
                        .lineSpacing(2)
                        .foregroundStyle(DS.Palette.ink3)
                }
                Spacer()
                Text("\(Int(value))\(suffix)")
                    .font(DS.Font.mono(13))
                    .foregroundStyle(DS.Palette.ink2)
            }
            Slider(value: $value, in: min...max)
                .tint(DS.Palette.accent)
                .disabled(isMock)
        }
        .padding(.vertical, 18)
    }
}
