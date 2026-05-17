import SwiftUI

struct HotkeyGestureCard: View {
    let title: String
    let description: String
    let gesture: String
    let kicker: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: kicker, color: DS.Palette.ink3)
                .padding(.bottom, 12)

            Text(title)
                .font(DS.Font.serif(28))
                .foregroundStyle(DS.Palette.ink)
                .padding(.bottom, 8)

            Text(description)
                .font(DS.Font.sans(13))
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)

            Text(gesture)
                .font(DS.Font.mono(10))
                .foregroundStyle(DS.Palette.ink3)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DS.Palette.ruleSoft, lineWidth: 1)
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.panel)
                .fill(DS.Palette.paperCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.panel)
                .stroke(DS.Palette.ruleSoft, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}
