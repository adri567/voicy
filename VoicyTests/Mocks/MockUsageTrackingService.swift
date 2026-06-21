@testable import Voicy
import Synchronization

/// In-memory `UsageTrackingService` for tests. A test can preload usage (to
/// simulate a tapped-out Free user) and assert what got booked after an action.
///
/// `Mutex`-backed for a genuinely `Sendable` conformance — the same reason as
/// `MockEntitlementService`: it's resolved through nonisolated Factory closures.
final class MockUsageTrackingService: UsageTrackingService {
    private struct Counters {
        var words: Int
        var fileMinutes: Int
    }

    private let counters: Mutex<Counters>

    nonisolated init(words: Int = 0, fileMinutes: Int = 0) {
        counters = Mutex(Counters(words: words, fileMinutes: fileMinutes))
    }

    /// Read accessor for assertions.
    var words: Int { counters.withLock { $0.words } }
    var fileMinutes: Int { counters.withLock { $0.fileMinutes } }

    func wordsUsedLast7Days() -> Int { counters.withLock { $0.words } }
    func recordWords(_ count: Int) { counters.withLock { $0.words += count } }
    func fileMinutesUsedThisMonth() -> Int { counters.withLock { $0.fileMinutes } }
    func recordFileMinutes(_ minutes: Int) { counters.withLock { $0.fileMinutes += minutes } }
}
