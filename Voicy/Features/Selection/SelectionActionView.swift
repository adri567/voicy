import SwiftUI

/// The clickable pill that appears above the recording overlay when text is
/// selected in another app. MVP: a single icon button; the tap is a no-op until
/// the transform flow lands.
struct SelectionActionView: View {
    let viewModel: SelectionViewModel

    var body: some View {
        Button {
            viewModel.handleTap()
        } label: {
            Image(systemName: "wand.and.sparkles")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 28)
        }
        .buttonStyle(.plain)
        .selectionPill()
        .accessibilityLabel("Improve selected text")
    }
}

private extension View {
    /// Mirrors the recording overlay's pill styling (black capsule, hairline
    /// white border).
    func selectionPill() -> some View {
        background(.black.opacity(0.8), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
    }
}
