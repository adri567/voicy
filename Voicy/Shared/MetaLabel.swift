import SwiftUI

struct MetaLabel: View {
    let text: String
    var color: Color = DS.Palette.ink3
    var body: some View {
        Text(text)
            .font(DS.Font.mono(10, weight: .regular))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(color)
    }
}
