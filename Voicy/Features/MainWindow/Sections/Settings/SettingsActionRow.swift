import SwiftUI

/// Neutral label + description + outlined action button, matching the editorial
/// settings style. For non-destructive actions (open a folder, reveal logs);
/// destructive ones use `SettingsDangerButtonRow`.
struct SettingsActionRow: View {
    let label: String
    let description: String
    let buttonTitle: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Text(description)
                    .font(DS.Font.sans(11))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
                    .frame(maxWidth: 440, alignment: .leading)
            }
            Spacer()
            Button(action: action) {
                HStack(spacing: 6) {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(buttonTitle)
                }
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 18)
    }
}
