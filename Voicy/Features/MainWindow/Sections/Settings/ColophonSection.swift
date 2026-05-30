import SwiftUI

/// Settings colophon: every Voicy engine/brain name mapped to the open-source
/// model that runs underneath, with copyright and license. Reads entirely from
/// `ModelCatalog` so it never drifts from the library views.
struct ColophonSection: View {
    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Colophon")
                    .font(DS.Font.serif(22))
                    .tracking(-0.3)
                Text("What's under the hood — and the licenses that make it possible.")
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.top, 12)

            panel
                .frame(maxWidth: .infinity)
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Voicy stands on the shoulders of remarkable open-source work. Each engine and brain wears a Voicy name in the interface — here's what actually runs underneath, with the licenses we ship under.")
                .font(DS.Font.sans(13))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 560, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)

            group(kicker: "Engines · Speech-to-Text", credits: ModelCatalog.engineCredits)
                .padding(.bottom, 28)

            group(kicker: "Brains · Language models", credits: ModelCatalog.brainCredits)

            legend
                .padding(.top, 28)

            Text("All model weights live on this Mac.")
                .font(DS.Font.mono(10))
                .foregroundStyle(DS.Palette.ink3)
                .padding(.top, 18)
        }
        .padding(28)
        .background(DS.Palette.paper2, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }

    private func group(kicker: String, credits: [ModelCredit]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            MetaLabel(text: kicker)

            VStack(spacing: 0) {
                ForEach(Array(credits.enumerated()), id: \.element.id) { idx, credit in
                    ColophonCreditRow(credit: credit, first: idx == 0)
                }
            }
            .padding(.horizontal, 22)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.small).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetaLabel(text: "The licenses, in plain language")

            HStack(alignment: .top, spacing: 22) {
                ForEach(ModelLicense.allCases) { license in
                    LicenseLegendTile(license: license)
                }
            }
        }
        .padding(20)
        .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.small))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.small).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}
