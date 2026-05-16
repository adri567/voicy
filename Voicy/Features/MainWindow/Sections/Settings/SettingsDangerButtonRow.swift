import SwiftUI

struct SettingsDangerButtonRow: View {
    let label: String
    var isMock: Bool = false
    var description: String? = nil
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(label) { action() }
                .buttonStyle(.plain)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(Color(red: 0.659, green: 0.200, blue: 0.122))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(Capsule().stroke(Color(red: 0.659, green: 0.200, blue: 0.122).opacity(0.4), lineWidth: 1))
                .disabled(isMock)
            if isMock { SettingsMockBadge() }
            if let description {
                Text(description)
                    .font(DS.Font.sans(11))
                    .foregroundStyle(DS.Palette.ink3)
                    .lineSpacing(2)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding(.vertical, 18)
    }
}
