import SwiftUI

/// The pill above the recording overlay shown when text is selected in another
/// app: two action buttons (proofread, rephrase) side by side.
struct SelectionActionView: View {
    let viewModel: SelectionViewModel

    var body: some View {
        HStack(spacing: 6) {
            SelectionActionButton(action: .proofread, viewModel: viewModel)
            SelectionActionButton(action: .rephrase, viewModel: viewModel)
        }
    }
}
