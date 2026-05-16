import SwiftUI

struct OnboardingBulletRow: View {
    let glyph: String?
    let label: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                if let glyph {
                    Text(glyph)
                        .font(DS.Font.sans(15, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                }
            }
            .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DS.Font.serif(17, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Text(desc)
                    .font(DS.Font.sans(13))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(DS.Palette.ruleSoft).frame(height: 1)
        }
    }
}
