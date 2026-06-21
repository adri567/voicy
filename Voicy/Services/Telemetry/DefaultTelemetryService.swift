import Foundation
import Sentry

/// Sentry-backed telemetry. A stateless wrapper around the global, thread-safe
/// `SentrySDK`, so it's a `nonisolated final class` (no actor needed) per the
/// project's concurrency rules — same shape as `DefaultPasteService`.
///
/// Privacy is enforced in two layers: call sites only ever pass metadata, and
/// `beforeSend`/`beforeBreadcrumb` scrub defensively as a backstop. PII and
/// performance tracing are off.
nonisolated final class DefaultTelemetryService: TelemetryService {
    private let config: SentryConfig

    nonisolated init(config: SentryConfig) {
        self.config = config
    }

    nonisolated func start() {
        guard config.isConfigured, isEnabled else { return }
        let dsn = config.dsn
        let environment = config.environment
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            // Crash + error + breadcrumbs only — no PII, no tracing, no sessions.
            options.sendDefaultPii = false
            options.tracesSampleRate = 0
            options.enableAutoSessionTracking = false
            options.attachStacktrace = true
            options.beforeSend = { event in Self.scrub(event) }
            options.beforeBreadcrumb = { crumb in Self.scrub(crumb) }
        }
    }

    nonisolated func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Preferences.Key.telemetryEnabled)
        if enabled {
            start()
        } else {
            SentrySDK.close()
        }
    }

    nonisolated func capture(_ error: Error, context: [String: String]) {
        guard isEnabled else { return }
        SentrySDK.capture(error: error) { scope in
            if !context.isEmpty {
                scope.setContext(value: context, key: "voicy")
            }
        }
    }

    nonisolated func capture(message: String, level: TelemetryLevel) {
        guard isEnabled else { return }
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
    }

    nonisolated func breadcrumb(_ message: String, category: BreadcrumbCategory) {
        guard isEnabled else { return }
        let crumb = Breadcrumb(level: .info, category: category.rawValue)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }

    /// Reflects the Settings opt-out, read fresh each call so the toggle takes
    /// effect immediately. Absent key means enabled (the default), so we can't
    /// use `bool(forKey:)` — that would default to `false`/off.
    private nonisolated var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Preferences.Key.telemetryEnabled) as? Bool ?? true
    }

    // MARK: - Scrubbing backstop

    /// Call sites never attach user content, but strip free-text bags that could
    /// in theory carry it. The crash/exception structure stays intact.
    private nonisolated static func scrub(_ event: Event) -> Event? {
        event.extra = nil
        event.request = nil
        return event
    }

    /// Breadcrumbs carry only their constant message + category — drop any data.
    private nonisolated static func scrub(_ crumb: Breadcrumb) -> Breadcrumb? {
        crumb.data = nil
        return crumb
    }
}

private extension TelemetryLevel {
    nonisolated var sentryLevel: SentryLevel {
        switch self {
        case .debug: .debug
        case .info: .info
        case .warning: .warning
        case .error: .error
        case .fatal: .fatal
        }
    }
}
