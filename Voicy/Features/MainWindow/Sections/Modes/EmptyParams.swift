import SwiftUI

struct EmptyParams: View {
    let title: String
    let bodyText: String

    init(title: String, body: String) {
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Font.serif(17))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink)
            Text(bodyText)
                .font(DS.Font.sans(13))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Palette.paper2, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}
