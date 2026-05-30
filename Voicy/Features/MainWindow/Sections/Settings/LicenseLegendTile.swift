import SwiftUI

/// One license explained in plain language for the colophon legend.
struct LicenseLegendTile: View {
    let license: ModelLicense

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(license.label)
                .font(DS.Font.serif(16, weight: .medium))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink)
            Text(license.plainLanguage)
                .font(DS.Font.sans(12))
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
