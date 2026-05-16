import SwiftUI

struct LangPicker: View {
    let value: String
    let excludeCode: String
    let onPick: (String) -> Void

    @State private var open = false

    private var lang: AppLanguage { LanguageCatalog.language(for: value) }

    var body: some View {
        Button(action: { open.toggle() }) {
            HStack(spacing: 12) {
                Text(lang.flag).font(.system(size: 18))
                Text(lang.native)
                    .font(DS.Font.sans(14, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .top) {
            LanguageGrid(excludeCode: excludeCode, selected: value) { code in
                onPick(code)
                open = false
            }
        }
    }
}
