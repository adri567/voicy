import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let caption: String
    let content: () -> Content

    init(title: String, caption: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DS.Font.serif(22))
                    .tracking(-0.3)
                Text(caption)
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.top, 12)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
            .dsPanel()
            .frame(maxWidth: .infinity)
        }
    }
}
