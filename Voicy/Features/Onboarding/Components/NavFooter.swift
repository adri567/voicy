import SwiftUI

struct NavFooter: View {
    let primary: String
    var primaryDisabled: Bool = false
    let onContinue: () -> Void
    var secondary: String? = nil
    var onSkip: (() -> Void)? = nil
    var note: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            PrimaryButton(title: primary, disabled: primaryDisabled, action: onContinue)
            if let secondary, let onSkip {
                GhostButton(title: secondary, action: onSkip)
            }
            if let note, !note.isEmpty {
                MetaLabel(text: note)
                    .padding(.leading, 6)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}
