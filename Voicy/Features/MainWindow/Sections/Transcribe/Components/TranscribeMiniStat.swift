import SwiftUI

struct TranscribeMiniStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(DS.Font.serif(26))
                .tracking(-0.2)
                .monospacedDigit()
                .foregroundStyle(DS.Palette.ink)
                .lineLimit(1)
            MetaLabel(text: label)
                .font(DS.Font.mono(8, weight: .regular))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
