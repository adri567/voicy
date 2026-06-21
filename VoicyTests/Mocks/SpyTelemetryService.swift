@testable import Voicy
import Foundation
import Synchronization

/// Records captured errors/messages and breadcrumbs so telemetry wiring can be
/// asserted without starting Sentry. `Mutex`-backed for a genuine `Sendable`
/// conformance — it's resolved through nonisolated Factory closures and called
/// from nonisolated service methods, the same reason as `MockUsageTrackingService`.
final class SpyTelemetryService: TelemetryService {

    struct Capture: Sendable {
        let summary: String
        let context: [String: String]
    }

    private struct Recorded {
        var captures: [Capture] = []
        var breadcrumbs: [String] = []
        var enabledCalls: [Bool] = []
        var started = false
    }

    private let recorded = Mutex(Recorded())

    nonisolated init() {}

    nonisolated func start() {
        recorded.withLock { $0.started = true }
    }

    nonisolated func setEnabled(_ enabled: Bool) {
        recorded.withLock { $0.enabledCalls.append(enabled) }
    }

    nonisolated func capture(_ error: Error, context: [String: String]) {
        recorded.withLock { $0.captures.append(Capture(summary: String(describing: error), context: context)) }
    }

    nonisolated func capture(message: String, level: TelemetryLevel) {
        recorded.withLock { $0.captures.append(Capture(summary: message, context: [:])) }
    }

    nonisolated func breadcrumb(_ message: String, category: BreadcrumbCategory) {
        recorded.withLock { $0.breadcrumbs.append("\(category.rawValue):\(message)") }
    }

    // MARK: - Read accessors for assertions

    var captures: [Capture] { recorded.withLock { $0.captures } }
    var breadcrumbs: [String] { recorded.withLock { $0.breadcrumbs } }
    var enabledCalls: [Bool] { recorded.withLock { $0.enabledCalls } }
    var didStart: Bool { recorded.withLock { $0.started } }

    /// The `stage` tag of every captured error, for terse assertions.
    func capturedStages() -> [String] {
        recorded.withLock { $0.captures.compactMap { $0.context["stage"] } }
    }
}
