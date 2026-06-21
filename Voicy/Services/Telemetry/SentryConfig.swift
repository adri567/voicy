import Foundation

/// Sentry connection settings, loaded at runtime from a bundled `Sentry.plist`.
/// The DSN isn't a secret — it ships inside every app and only permits *sending*
/// events — but it's kept out of source per the project's no-hardcoding rule:
/// the real file is gitignored, with `Sentry.example.plist` checked in as a
/// template. Mirrors the `LemonSqueezyConfig` pattern.
///
/// While the plist is missing or still holds the placeholder DSN, telemetry
/// stays off (`isConfigured == false`) so dev/test builds never start Sentry.
nonisolated struct SentryConfig: Sendable {
    let dsn: String
    let environment: String

    /// True once a real DSN is present — gates SDK startup. A valid Sentry DSN
    /// is always an https URL; the placeholder in the template is not.
    var isConfigured: Bool { dsn.hasPrefix("https://") }

    /// Reads the bundled plist; falls back to an empty (unconfigured) value when
    /// it's absent — which is the normal case in dev and test.
    static func loadFromBundle(_ bundle: Bundle = .main) -> SentryConfig {
        guard
            let url = bundle.url(forResource: "Sentry", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return SentryConfig(dsn: "", environment: "development")
        }
        let dsn = (dict["DSN"] as? String) ?? ""
        let environment = (dict["Environment"] as? String) ?? "production"
        return SentryConfig(dsn: dsn, environment: environment)
    }
}
