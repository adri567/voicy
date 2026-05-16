import SwiftUI

struct SourceLanguageGrid: View {
    let selected: String
    let onPick: (String) -> Void

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(LanguageCatalog.all) { lang in
                Button(action: { onPick(lang.code) }) {
                    HStack(spacing: 10) {
                        Text(lang.flag).font(.system(size: 18))
                        Text(lang.native)
                            .font(DS.Font.sans(13, weight: .medium))
                            .foregroundStyle(lang.code == selected ? DS.Palette.paper : DS.Palette.ink)
                        Spacer(minLength: 0)
                        Text(lang.code.uppercased())
                            .font(DS.Font.mono(9))
                            .tracking(0.6)
                            .foregroundStyle(lang.code == selected ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minWidth: 180, alignment: .leading)
                    .background(
                        lang.code == selected ? DS.Palette.ink : .clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 380)
        .background(DS.Palette.paper)
        .preferredColorScheme(.light)
    }
}
