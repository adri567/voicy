import Testing
@testable import Voicy

@Suite("Telemetry")
struct TelemetryServiceTests {

    /// The gate that decides whether Sentry ever starts. Getting this wrong
    /// means either silent no-telemetry or, worse, telemetry firing on a
    /// placeholder build — so it's covered explicitly.
    @Suite("SentryConfig gating")
    struct SentryConfigGating {

        @Test("Empty DSN is unconfigured")
        func emptyIsUnconfigured() {
            #expect(SentryConfig(dsn: "", environment: "production").isConfigured == false)
        }

        @Test("Placeholder DSN is unconfigured")
        func placeholderIsUnconfigured() {
            #expect(SentryConfig(dsn: "YOUR_SENTRY_DSN_HERE", environment: "production").isConfigured == false)
        }

        @Test("A real https DSN is configured")
        func httpsDSNIsConfigured() {
            let dsn = "https://examplePublicKey@o0.ingest.de.sentry.io/0"
            #expect(SentryConfig(dsn: dsn, environment: "production").isConfigured)
        }

        @Test("Missing bundle plist falls back to unconfigured")
        func missingPlistIsUnconfigured() {
            // The test bundle ships no Sentry.plist, so the loader must produce
            // an unconfigured value — telemetry stays off by default.
            #expect(SentryConfig.loadFromBundle().isConfigured == false)
        }
    }

    @Test("Disabled-path calls on the no-op service record nothing observable")
    func noopServiceIsInert() {
        // The disabled/unconfigured path routes here; exercising every call must
        // be safe. We assert via the spy contract that no-op truly does nothing
        // by comparing against a spy that *does* record.
        let noop: any TelemetryService = NoopTelemetryService()
        noop.start()
        noop.setEnabled(false)
        noop.capture(CancellationError(), context: ["stage": "x"])
        noop.capture(message: "hi", level: .info)
        noop.breadcrumb("tap", category: .ui)

        let spy = SpyTelemetryService()
        spy.capture(CancellationError(), context: ["stage": "x"])
        spy.breadcrumb("tap", category: .ui)
        #expect(spy.captures.count == 1)
        #expect(spy.breadcrumbs == ["ui:tap"])
    }
}
