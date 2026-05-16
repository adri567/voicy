import SwiftUI

/// Two-column screen scaffold used by every onboarding step.
/// Editorial left column (title + lead + body + footer), right column (form / illustration).
struct ScreenShell<Title: View, LeftBody: View, LeftFooter: View, Right: View>: View {
    let chapter: String
    let kicker: String
    let titleView: Title
    let lead: String?
    let leftBody: LeftBody
    let leftFooter: LeftFooter
    let rightCol: Right

    init(
        chapter: String,
        kicker: String,
        @ViewBuilder title: () -> Title,
        lead: String? = nil,
        @ViewBuilder body leftBody: () -> LeftBody = { EmptyView() },
        @ViewBuilder leftFooter: () -> LeftFooter = { EmptyView() },
        @ViewBuilder rightCol: () -> Right
    ) {
        self.chapter = chapter
        self.kicker = kicker
        self.titleView = title()
        self.lead = lead
        self.leftBody = leftBody()
        self.leftFooter = leftFooter()
        self.rightCol = rightCol()
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left column
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ \(kicker)", color: DS.Palette.accent)

                titleView
                    .padding(.top, 20)

                if let lead {
                    Text(lead)
                        .font(DS.Font.sans(16))
                        .lineSpacing(4)
                        .foregroundStyle(DS.Palette.ink2)
                        .frame(maxWidth: 460, alignment: .leading)
                        .padding(.top, 22)
                }

                leftBody
                    .padding(.top, 22)

                Spacer(minLength: 16)

                leftFooter
            }
            .padding(.horizontal, 56)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DS.Palette.paper)
            .overlay(alignment: .trailing) {
                Rectangle().fill(DS.Palette.ruleSoft).frame(width: 1)
            }

            // Right column
            rightCol
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Palette.paper2)
        }
    }
}
