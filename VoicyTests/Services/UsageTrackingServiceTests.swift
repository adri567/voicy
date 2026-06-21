import Foundation
import Synchronization
import Testing
@testable import Voicy

/// Advanceable clock for the usage tests. The service captures `now` once as a
/// `@Sendable` closure; this box lets a test move time forward afterwards
/// without the data race of mutating a captured `var`.
private final class TestClock: Sendable {
    private let instant: Mutex<Date>
    init(_ start: Date) { instant = Mutex(start) }
    var now: @Sendable () -> Date { { [self] in instant.withLock { $0 } } }
    func set(_ date: Date) { instant.withLock { $0 = date } }
}

@MainActor
@Suite("DefaultUsageTrackingService")
struct UsageTrackingServiceTests {

    /// Fresh, isolated defaults per test so the rolling-window and month-rollover
    /// assertions never see another test's writes.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "usage.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    private func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: iso)!
    }

    // MARK: - Words (rolling 7 days)

    @Test("recordWords accumulates into today's bucket")
    func recordsWords() {
        let defaults = makeDefaults()
        let now = date("2026-05-31T12:00:00Z")
        let service = DefaultUsageTrackingService(defaults: defaults, now: { now })

        service.recordWords(40)
        service.recordWords(60)
        #expect(service.wordsUsedLast7Days() == 100)
    }

    @Test("Non-positive word counts are ignored")
    func ignoresNonPositiveWords() {
        let defaults = makeDefaults()
        let now = date("2026-05-31T12:00:00Z")
        let service = DefaultUsageTrackingService(defaults: defaults, now: { now })

        service.recordWords(0)
        service.recordWords(-5)
        #expect(service.wordsUsedLast7Days() == 0)
    }

    @Test("Words within the 7-day window are summed")
    func sumsWithinWindow() {
        let defaults = makeDefaults()
        let clock = TestClock(date("2026-05-25T12:00:00Z"))
        let service = DefaultUsageTrackingService(defaults: defaults, now: clock.now)

        service.recordWords(100)                       // day 0
        clock.set(date("2026-05-31T12:00:00Z"))        // 6 days later — inside window
        service.recordWords(50)
        #expect(service.wordsUsedLast7Days() == 150)
    }

    @Test("Words older than 7 days drop out of the rolling window")
    func dropsOutsideWindow() {
        let defaults = makeDefaults()
        let clock = TestClock(date("2026-05-20T12:00:00Z"))
        let service = DefaultUsageTrackingService(defaults: defaults, now: clock.now)

        service.recordWords(100)                       // 2026-05-20
        clock.set(date("2026-05-31T12:00:00Z"))        // 11 days later — outside window
        #expect(service.wordsUsedLast7Days() == 0)
    }

    @Test("A new service instance reads persisted word usage")
    func wordsPersist() {
        let defaults = makeDefaults()
        let now = date("2026-05-31T12:00:00Z")
        DefaultUsageTrackingService(defaults: defaults, now: { now }).recordWords(75)

        let reloaded = DefaultUsageTrackingService(defaults: defaults, now: { now })
        #expect(reloaded.wordsUsedLast7Days() == 75)
    }

    // MARK: - File minutes (per calendar month)

    @Test("recordFileMinutes accumulates into the current month")
    func recordsFileMinutes() {
        let defaults = makeDefaults()
        let now = date("2026-05-31T12:00:00Z")
        let service = DefaultUsageTrackingService(defaults: defaults, now: { now })

        service.recordFileMinutes(10)
        service.recordFileMinutes(5)
        #expect(service.fileMinutesUsedThisMonth() == 15)
    }

    @Test("File minutes reset at the month boundary")
    func fileMinutesResetMonthly() {
        let defaults = makeDefaults()
        let clock = TestClock(date("2026-05-31T12:00:00Z"))
        let service = DefaultUsageTrackingService(defaults: defaults, now: clock.now)

        service.recordFileMinutes(20)
        #expect(service.fileMinutesUsedThisMonth() == 20)

        clock.set(date("2026-06-01T00:30:00Z"))  // next month
        #expect(service.fileMinutesUsedThisMonth() == 0)
        service.recordFileMinutes(5)
        #expect(service.fileMinutesUsedThisMonth() == 5)
    }

    @Test("Non-positive file minutes are ignored")
    func ignoresNonPositiveMinutes() {
        let defaults = makeDefaults()
        let now = date("2026-05-31T12:00:00Z")
        let service = DefaultUsageTrackingService(defaults: defaults, now: { now })

        service.recordFileMinutes(0)
        service.recordFileMinutes(-3)
        #expect(service.fileMinutesUsedThisMonth() == 0)
    }

    // MARK: - Billable-minute rounding (TranscribeViewModel policy)

    @Test("billableMinutes rounds partial minutes up", arguments: [
        (0.0, 0), (1.0, 1), (59.0, 1), (60.0, 1), (61.0, 2), (150.0, 3),
    ])
    func billableMinutesRounding(seconds: Double, expected: Int) {
        #expect(TranscribeViewModel.billableMinutes(seconds: seconds) == expected)
    }
}
