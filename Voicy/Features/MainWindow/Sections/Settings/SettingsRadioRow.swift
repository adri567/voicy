import SwiftUI

struct SettingsRadioRow: View {
    /// Tightly coupled to `SettingsRadioRow` — no value beyond labelling a
    /// single radio choice. Kept in the same file as a Vertragspaar (the
    /// CLAUDE.md exception for tight DTO+host pairs).
    struct Option: Identifiable {
        let id: String
        let label: String
        let sub: String
    }

    let label: String
    let desc: String
    @Binding var value: String
    let options: [Option]
    let isMock: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack(spacing: 10) {
                ForEach(options) { opt in
                    let active = value == opt.id
                    Button {
                        if !isMock { value = opt.id }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(opt.label)
                                .font(DS.Font.sans(13, weight: .semibold))
                                .foregroundStyle(active ? DS.Palette.paper : DS.Palette.ink)
                            Text(opt.sub)
                                .font(DS.Font.sans(11))
                                .foregroundStyle(active ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(active ? DS.Palette.ink : DS.Palette.paper)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(active ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 18)
    }
}
