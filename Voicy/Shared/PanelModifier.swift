import SwiftUI

struct PanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
    }
}
