import SwiftUI

struct OnboardingKbd: View {
    let label: String
    var dark: Bool = false
    var body: some View {
        Text(label)
            .font(DS.Font.mono(11, weight: .medium))
            .foregroundStyle(dark ? DS.Palette.accentInk : DS.Palette.ink)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(dark ? Color(red: 0.165, green: 0.149, blue: 0.122) : DS.Palette.paperCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(dark ? Color.white.opacity(0.1) : DS.Palette.ink.opacity(0.18), lineWidth: 1)
            )
    }
}
