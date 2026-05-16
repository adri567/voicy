import SwiftUI

/// Tiny keycap pill. When `highlighted` is true the cap renders in the
/// editorial yellow used on the Hotkey page to flag the active trigger.
struct Kbd: View {
    let label: String
    let highlighted: Bool

    init(_ label: String, highlighted: Bool = false) {
        self.label = label
        self.highlighted = highlighted
    }

    var body: some View {
        Text(label)
            .font(DS.Font.mono(10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                highlighted ? DS.Palette.highlight : DS.Palette.paper,
                in: RoundedRectangle(cornerRadius: DS.Radius.kbd)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.kbd)
                    .stroke(highlighted ? Color.black.opacity(0.18) : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .foregroundStyle(DS.Palette.ink)
    }
}
