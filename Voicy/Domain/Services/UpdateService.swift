/// Drives in-app application updates (Sparkle). Lives on the main actor because
/// the update flow is UI-driven; resolved via Factory like the other services.
protocol UpdateService: Sendable {
    /// Whether a user-initiated update check can currently run. Mirrors
    /// Sparkle's own readiness flag (false while a check is already in flight).
    var canCheckForUpdates: Bool { get }

    /// Starts a user-initiated update check, presenting Sparkle's standard UI.
    func checkForUpdates()
}
