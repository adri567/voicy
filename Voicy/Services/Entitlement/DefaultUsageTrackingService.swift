import Foundation

/// `UserDefaults`-backed usage counters. Words are bucketed per calendar day
/// (`yyyy-MM-dd`) and summed over a rolling 7-day window; file minutes are
/// bucketed per calendar month (`yyyy-MM`). Stale buckets are pruned on every
/// write so the stored dictionaries stay small.
///
/// `defaults` and `now` are injectable so tests can use an isolated suite
/// (`TestDefaults.make()`) and drive the clock to assert the rolling-window and
/// month-rollover behaviour deterministically.
final class DefaultUsageTrackingService: UsageTrackingService {

    private let defaults: UserDefaults
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let dayFormatter: DateFormatter
    private let monthFormatter: DateFormatter

    /// Keep two weeks of day buckets — one week of live window plus a buffer so
    /// a clock that drifts slightly never drops a still-relevant day.
    private static let dayBucketRetention = 14
    /// Keep three months of file-minute buckets as a safety buffer.
    private static let monthBucketRetention = 3

    init(
        defaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.defaults = defaults
        self.now = now

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        self.calendar = cal

        let day = DateFormatter()
        day.calendar = cal
        day.timeZone = cal.timeZone
        day.locale = Locale(identifier: "en_US_POSIX")
        day.dateFormat = "yyyy-MM-dd"
        self.dayFormatter = day

        let month = DateFormatter()
        month.calendar = cal
        month.timeZone = cal.timeZone
        month.locale = Locale(identifier: "en_US_POSIX")
        month.dateFormat = "yyyy-MM"
        self.monthFormatter = month
    }

    // MARK: - Words (rolling 7 days)

    func wordsUsedLast7Days() -> Int {
        let buckets = wordBuckets()
        return last7DayKeys().reduce(0) { $0 + (buckets[$1] ?? 0) }
    }

    func recordWords(_ count: Int) {
        guard count > 0 else { return }
        var buckets = wordBuckets()
        buckets[dayFormatter.string(from: now()), default: 0] += count
        pruneDayBuckets(&buckets)
        defaults.set(buckets, forKey: Preferences.Key.usageWordBuckets)
    }

    // MARK: - File minutes (per calendar month)

    func fileMinutesUsedThisMonth() -> Int {
        monthBuckets()[monthFormatter.string(from: now())] ?? 0
    }

    func recordFileMinutes(_ minutes: Int) {
        guard minutes > 0 else { return }
        var buckets = monthBuckets()
        buckets[monthFormatter.string(from: now()), default: 0] += minutes
        pruneMonthBuckets(&buckets)
        defaults.set(buckets, forKey: Preferences.Key.usageFileMinuteBuckets)
    }

    // MARK: - Storage

    private func wordBuckets() -> [String: Int] {
        (defaults.dictionary(forKey: Preferences.Key.usageWordBuckets) as? [String: Int]) ?? [:]
    }

    private func monthBuckets() -> [String: Int] {
        (defaults.dictionary(forKey: Preferences.Key.usageFileMinuteBuckets) as? [String: Int]) ?? [:]
    }

    /// Day keys for today and the previous six days — the rolling window.
    private func last7DayKeys() -> [String] {
        let today = now()
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
                .map { dayFormatter.string(from: $0) }
        }
    }

    private func pruneDayBuckets(_ buckets: inout [String: Int]) {
        guard let cutoffDate = calendar.date(
            byAdding: .day, value: -Self.dayBucketRetention, to: now()
        ) else { return }
        let cutoff = dayFormatter.string(from: cutoffDate)
        buckets = buckets.filter { $0.key >= cutoff }
    }

    private func pruneMonthBuckets(_ buckets: inout [String: Int]) {
        guard let cutoffDate = calendar.date(
            byAdding: .month, value: -Self.monthBucketRetention, to: now()
        ) else { return }
        let cutoff = monthFormatter.string(from: cutoffDate)
        buckets = buckets.filter { $0.key >= cutoff }
    }
}
