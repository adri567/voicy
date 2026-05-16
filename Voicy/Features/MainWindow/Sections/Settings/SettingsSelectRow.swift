import SwiftUI

struct SettingsSelectRow: View {
    let label: String
    let desc: String
    @Binding var value: String
    let options: [String]
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
            Picker("", selection: $value) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .frame(minWidth: 220)
            .disabled(isMock)
        }
        .padding(.vertical, 18)
    }
}
