import SwiftUI

struct TagPillModifier: ViewModifier {
    var solid: Bool = false
    var accent: Bool = false

    func body(content: Content) -> some View {
        content
            .font(DS.Font.mono(10, weight: .regular))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(background, in: Capsule())
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
    }

    private var textColor: Color {
        if accent { return DS.Palette.accentInk }
        if solid  { return DS.Palette.paper }
        return DS.Palette.ink2
    }
    private var background: Color {
        if accent { return DS.Palette.accent }
        if solid  { return DS.Palette.ink }
        return .clear
    }
    private var borderColor: Color {
        if accent { return DS.Palette.accent }
        if solid  { return DS.Palette.ink }
        return DS.Palette.ruleSoft
    }
}
