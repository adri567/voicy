import SwiftUI

struct SettingsDangerButtonRow: View {
    let label: String
    let isMock: Bool

    var body: some View {
        HStack {
            Button(label) {}
                .buttonStyle(.plain)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(Color(red: 0.659, green: 0.200, blue: 0.122))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(Capsule().stroke(Color(red: 0.659, green: 0.200, blue: 0.122).opacity(0.4), lineWidth: 1))
                .disabled(isMock)
            if isMock { SettingsMockBadge() }
            Spacer()
        }
        .padding(.vertical, 18)
    }
}
