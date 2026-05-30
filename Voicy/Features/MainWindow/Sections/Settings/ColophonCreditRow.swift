import SwiftUI

/// One colophon line: the Voicy name + tier, the real model it's powered by,
/// its copyright, and the license badge it ships under.
struct ColophonCreditRow: View {
    let credit: ModelCredit
    let first: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !first { SoftDivider() }

            HStack(alignment: .firstTextBaseline, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(credit.voicyName)
                        .font(DS.Font.serif(19, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(DS.Palette.ink)
                        .fixedSize()
                    Text(credit.tier).dsTag()
                }
                .frame(width: 170, alignment: .leading)

                VStack(alignment: .leading, spacing: 1) {
                    Text(credit.underlyingModel)
                        .font(DS.Font.sans(13, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                    Text(credit.copyright)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Text(credit.license.label)
                    .font(DS.Font.mono(10))
                    .tracking(0.6)
                    .foregroundStyle(DS.Palette.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.Palette.paper3, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Palette.ruleSoft, lineWidth: 1))
            }
            .padding(.vertical, 14)
        }
    }
}
