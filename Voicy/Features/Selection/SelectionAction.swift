/// An LLM transform the selection-action pill can run on the selected text.
nonisolated enum SelectionAction: CaseIterable, Equatable {
    /// Fix spelling/grammar/punctuation and lightly polish.
    case proofread
    /// Neutrally reword the text (different phrasing, same meaning/tone/language).
    case rephrase

    /// SF Symbol shown on the button.
    var icon: String {
        switch self {
        case .proofread: "wand.and.sparkles"
        case .rephrase:  "arrow.2.squarepath"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .proofread: "Proofread selected text"
        case .rephrase:  "Rephrase selected text"
        }
    }
}
