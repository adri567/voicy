import SwiftUI

/// One action button in the selection pill. Shows its action's icon, a spinner
/// while *this* action runs, or a warning if *this* action just failed. All
/// buttons disable while any action is in flight.
struct SelectionActionButton: View {
    let action: SelectionAction
    let viewModel: SelectionViewModel

    var body: some View {
        Button {
            viewModel.run(action)
        } label: {
            content
                .frame(width: 34, height: 28)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phase == .working)
        .selectionPill()
        .accessibilityLabel(action.accessibilityLabel)
    }

    private var isActive: Bool { viewModel.runningAction == action }

    @ViewBuilder
    private var content: some View {
        if isActive, viewModel.phase == .working {
            ProgressView()
                .controlSize(.small)
                .tint(.white)
        } else if isActive, viewModel.phase == .failed {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.orange)
        } else {
            Image(systemName: action.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
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
