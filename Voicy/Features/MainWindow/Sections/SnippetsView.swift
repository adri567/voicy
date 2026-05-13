import SwiftUI

// MOCK: full feature not implemented. TODO(snippets).
struct SnippetsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 64) {
                    leftEssay
                        .frame(maxWidth: .infinity, alignment: .leading)
                    rightConcept
                        .frame(width: 360)
                }
                .padding(.horizontal, DS.Spacing.pageHPadding)
                .padding(.top, DS.Spacing.pageTop)
                .padding(.bottom, 60)

                HStack {
                    MetaLabel(text: "To be continued")
                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.pageHPadding)
                .padding(.bottom, 56)
            }
        }
    }

    private var leftEssay: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "◆ A note from the editor", color: DS.Palette.accent)
                .padding(.bottom, 18)

            Text("The \(Text("Snippets").italic().foregroundColor(DS.Palette.accent))\nchapter is still\nbeing written.")
                .font(DS.Font.serif(64))
                .tracking(-1.2)
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink)
                .padding(.bottom, 22)

            Text("We left this section deliberately empty. Snippets are quiet little shortcuts — say \(Text("\"best regards\"").italic().foregroundColor(DS.Palette.ink)) and have Voicy paste your full sign-off; say \(Text("\"kb shipping address\"").italic().foregroundColor(DS.Palette.ink)) and a real address appears. But the shape of that feature is yours to draw. Let's design it together.")
                .font(DS.Font.sans(16))
                .lineSpacing(5)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 580, alignment: .leading)
                .padding(.bottom, 32)

            HStack(spacing: 12) {
                Button("Sketch a snippet →") {}
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(13, weight: .semibold))
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .background(DS.Palette.ink, in: Capsule())

                Button("Read the brief") {}
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
            }
        }
    }

    private var rightConcept: some View {
        VStack(alignment: .leading, spacing: 16) {
            MetaLabel(text: "Concept · how it might feel")
                .padding(.bottom, -4)

            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "Trigger phrase")
                    .padding(.bottom, 12)
                Text("\"best regards\"")
                    .font(DS.Font.serifItalic(26))
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                MetaLabel(text: "Expands to")
                    .padding(.bottom, 12)
                Text("""
                Best regards,
                Adrian
                — sent from Voicy
                """)
                    .font(DS.Font.sans(14))
                    .lineSpacing(5)
                    .foregroundStyle(DS.Palette.ink2)
            }
            .padding(26)
            .dsPanel()

            VStack(alignment: .leading, spacing: 8) {
                MetaLabel(text: "Empty slot · for the next idea")
                Text("yours to fill —")
                    .font(DS.Font.serifItalic(22))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .strokeBorder(DS.Palette.ruleSoft, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            )
            .opacity(0.85)
        }
    }
}
