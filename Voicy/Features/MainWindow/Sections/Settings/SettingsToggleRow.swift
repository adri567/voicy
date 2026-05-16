import SwiftUI

struct SettingsToggleRow: View {
    let label: String
    let desc: String
    @Binding var value: Bool
    let isMock: Bool

    var body: some View {
        HStack(spacing: 18) {
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
            Toggle("", isOn: $value)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(DS.Palette.accent)
                .disabled(isMock)
        }
        .padding(.vertical, 18)
    }
}
