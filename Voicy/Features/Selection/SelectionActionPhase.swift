/// Visual state of the selection-action pill while it processes a correction.
nonisolated enum SelectionActionPhase: Equatable {
    /// Ready: shows the action icon, tap is enabled.
    case idle
    /// Correction in flight: shows a spinner, tap disabled.
    case working
    /// Last attempt failed (no brain, error or timeout): shows a brief hint
    /// before returning to `.idle`. The selection is left untouched.
    case failed
}
