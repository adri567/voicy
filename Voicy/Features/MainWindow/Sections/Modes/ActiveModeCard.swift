import SwiftUI

struct ActiveModeCard: View {
    let mode: Mode
    let index: Int
    let total: Int
    let sourceLanguage: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MetaLabel(text: "Now landing", color: DS.Palette.paper.opacity(0.6))
                Spacer()
                Text("SLOT \(String(format: "%02d", index + 1)) / \(String(format: "%02d", total))")
                    .font(DS.Font.mono(9))
                    .tracking(1.0)
                    .foregroundStyle(DS.Palette.paper.opacity(0.55))
            }
            .padding(.bottom, 16)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)

                    if let emoji = mode.displayEmoji {
                        Text(emoji).font(.system(size: 30))
                    } else {
                        Image(systemName: mode.type.systemImage)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(DS.Palette.paper)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title(source: sourceLanguage))
                        .font(DS.Font.serif(26))
                        .tracking(-0.3)
                        .foregroundStyle(DS.Palette.paper)
                    MetaLabel(text: mode.type.label, color: DS.Palette.paper.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            SoftDivider()
                .opacity(0.4)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                MetaLabel(text: "Sample output", color: DS.Palette.paper.opacity(0.45))
                Text(ModesSample.output(for: mode))
                    .font(DS.Font.serifItalic(14))
                    .lineSpacing(3)
                    .lineLimit(6)
                    .foregroundStyle(DS.Palette.paper.opacity(0.92))
            }
        }
        .padding(26)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
    }
}
