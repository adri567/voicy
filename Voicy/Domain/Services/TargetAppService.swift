import Foundation

protocol TargetAppService: Sendable {
    /// Snapshot der aktuell aktiven App (frontmost).
    /// Muss aufgerufen werden **bevor** Voicy einen Paste-Cmd+V triggert,
    /// sonst ist Voicy selbst frontmost.
    @MainActor func captureCurrent() -> TargetAppSnapshot?
}
