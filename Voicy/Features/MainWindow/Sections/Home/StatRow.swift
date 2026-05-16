import SwiftUI

struct StatRow: View {
    let big: String
    let label: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(big)
                .font(DS.Font.serif(44))
                .foregroundStyle(DS.Palette.ink)
            Text(label)
                .font(DS.Font.sans(12))
                .foregroundStyle(DS.Palette.ink3)
        }
        .padding(.bottom, 14)
    }
}
