import Foundation

/// Telemetry sink used when Sentry is unconfigured (no real DSN) — dev builds,
/// tests, and any release shipped without a `Sentry.plist`. Every call is a
/// no-op, so call sites stay unconditional.
nonisolated final class NoopTelemetryService: TelemetryService {
    nonisolated init() {}

    nonisolated func start() {}
    nonisolated func setEnabled(_ enabled: Bool) {}
    nonisolated func capture(_ error: Error, context: [String: String]) {}
    nonisolated func capture(message: String, level: TelemetryLevel) {}
    nonisolated func breadcrumb(_ message: String, category: BreadcrumbCategory) {}
}
