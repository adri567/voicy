import SwiftUI

struct SpecBlock: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MetaLabel(text: label)
                .font(DS.Font.mono(8, weight: .regular))
            Text(value)
                .font(DS.Font.mono(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
        }
    }
}
