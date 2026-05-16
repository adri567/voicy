import SwiftUI

struct SampleRow: View {
    let mode: Mode
    let index: Int
    let isFirst: Bool
    let isActive: Bool
    let sourceLanguage: AppLanguage
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if !isFirst {
                    SoftDivider()
                }
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(DS.Font.mono(11, weight: .medium))
                                .tracking(0.6)
                                .foregroundStyle(isActive ? DS.Palette.accent : DS.Palette.ink3)
                            glyphChip
                        }
                        Text(mode.title(source: sourceLanguage))
                            .font(DS.Font.sans(13, weight: .semibold))
                            .foregroundStyle(DS.Palette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(mode.type.label.uppercased())
                            .font(DS.Font.mono(8))
                            .tracking(1.2)
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    .frame(width: 140, alignment: .leading)

                    Text(ModesSample.output(for: mode))
                        .font(DS.Font.sans(15))
                        .lineSpacing(3)
                        .foregroundStyle(isActive ? DS.Palette.ink : DS.Palette.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glyphChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? DS.Palette.ink : DS.Palette.paper)
            RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1)
            if let emoji = mode.displayEmoji {
                Text(emoji).font(.system(size: 16))
            } else {
                Image(systemName: mode.type.systemImage)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
            }
        }
        .frame(width: 28, height: 28)
    }
}
