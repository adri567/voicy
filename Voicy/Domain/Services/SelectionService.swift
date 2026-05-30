import Foundation

/// Observes the text selection in the frontmost (non-Voicy) application and
/// publishes changes. Drives the selection-action pill above the recording
/// overlay.
protocol SelectionService: Sendable {
    /// Emits a new `SelectionState` whenever the frontmost app's selection
    /// changes (deduped — no repeats for an unchanged selection).
    nonisolated var selectionChanges: AsyncStream<SelectionState> { get }

    /// Begins polling the frontmost app for its selection.
    func start()

    /// Stops polling and emits an empty selection so subscribers hide any UI.
    func stop()

    /// Reads the frontmost app's current selection on demand (a fresh AX read,
    /// not the last polled value). Used at click time so the correction runs on
    /// exactly what's selected right now.
    func currentSelection() -> SelectionState

    /// Replaces the frontmost app's current selection with `text` via the
    /// Accessibility API. Returns `false` if the focused element doesn't accept
    /// a settable selected-text value (e.g. many Electron/web views), so callers
    /// can fall back to a paste.
    func setSelectedText(_ text: String) -> Bool
}

/// Snapshot of the current text selection in the frontmost app. `selectedText`
/// is retained for later transform features; the MVP only consumes
/// `hasSelection`.
nonisolated struct SelectionState: Sendable, Equatable {
    let hasSelection: Bool
    let selectedText: String

    static let none = SelectionState(hasSelection: false, selectedText: "")
}
