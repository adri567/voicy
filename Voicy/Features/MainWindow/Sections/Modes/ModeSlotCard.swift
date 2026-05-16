import SwiftUI

struct ModeSlotCard: View {
    let mode: Mode
    let index: Int
    let isActive: Bool
    let sourceLanguage: AppLanguage
    let onTap: () -> Void

    private var num: String { String(format: "%02d", index + 1) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(num)
                        .font(DS.Font.mono(10))
                        .tracking(1.0)
                        .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    Spacer()
                    Text(mode.type.label.uppercased())
                        .font(DS.Font.mono(8))
                        .tracking(1.2)
                        .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                }
                .padding(.bottom, 14)

                glyph
                    .frame(height: 48)
                    .padding(.bottom, 14)

                Text(mode.title(source: sourceLanguage))
                    .font(DS.Font.sans(14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)

                Text(subtitleText)
                    .font(DS.Font.mono(9))
                    .tracking(0.6)
                    .padding(.top, 4)
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(width: 168, height: 168, alignment: .topLeading)
            .background(isActive ? DS.Palette.ink : DS.Palette.paper,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glyph: some View {
        if let emoji = mode.displayEmoji {
            Text(emoji)
                .font(.system(size: 34))
        } else {
            Image(systemName: mode.type.systemImage)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
        }
    }

    private var subtitleText: String {
        if mode.type == .translate {
            let target = LanguageCatalog.language(for: mode.targetCode ?? "en")
            return "\(sourceLanguage.code.uppercased()) → \(target.code.uppercased())"
        }
        return mode.subtitleText
    }
}
