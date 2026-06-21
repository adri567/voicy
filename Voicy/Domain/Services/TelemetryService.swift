import Foundation

/// App-wide telemetry: crash reporting, captured (handled) errors, and
/// navigational breadcrumbs. Backed by Sentry in production; a no-op when
/// unconfigured (no bundled `Sentry.plist`) so dev and test builds never phone
/// home.
///
/// Privacy contract — implementations must NEVER receive transcribed text,
/// audio, snippet content, selected text, or custom-mode prompts. Call sites
/// pass only metadata (durations, counts, `ModeType.rawValue`, error type).
/// Breadcrumb messages are built from constant strings (optionally plus
/// numbers), never user content.
protocol TelemetryService: Sendable {
    /// Boots the SDK if telemetry is enabled and configured. Idempotent.
    nonisolated func start()

    /// Flips reporting on/off live from the Settings toggle. Persists the
    /// choice and starts/stops the SDK without an app relaunch.
    nonisolated func setEnabled(_ enabled: Bool)

    /// Records a handled error with optional non-PII context (e.g. stage, mode
    /// type). No-op while disabled.
    nonisolated func capture(_ error: Error, context: [String: String])

    /// Records a standalone message at the given level. No-op while disabled.
    nonisolated func capture(message: String, level: TelemetryLevel)

    /// Drops a navigational breadcrumb. The message MUST be a constant string
    /// (optionally plus numbers), never user content.
    nonisolated func breadcrumb(_ message: String, category: BreadcrumbCategory)
}

extension TelemetryService {
    /// Convenience overload — capture without extra context.
    nonisolated func capture(_ error: Error) {
        capture(error, context: [:])
    }
}

/// Severity for captured messages. Mirrors Sentry's levels without leaking the
/// dependency into call sites.
nonisolated enum TelemetryLevel: Sendable {
    case debug, info, warning, error, fatal
}

/// Stable breadcrumb categories so the Sentry timeline groups consistently.
nonisolated enum BreadcrumbCategory: String, Sendable {
    case recording, transcription, correction, selection, brain, file, license, ui
}
