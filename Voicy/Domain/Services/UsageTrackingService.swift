import Foundation

/// Tracks metered usage for the Free tier: dictation words over a rolling 7-day
/// window and file-transcription minutes per calendar month. The gates query
/// these counters before an action and book usage after a successful one.
///
/// Pro users are never metered, but recording still runs harmlessly — the gates
/// simply don't read the counters when `weeklyWordLimit`/`monthlyFileMinuteLimit`
/// are `nil`.
protocol UsageTrackingService: Sendable {
    /// Total dictation words recorded in the rolling last 7 days (today + 6).
    func wordsUsedLast7Days() -> Int

    /// Adds `count` words to today's bucket. No-op for non-positive counts.
    func recordWords(_ count: Int)

    /// File-transcription minutes booked in the current calendar month.
    func fileMinutesUsedThisMonth() -> Int

    /// Adds `minutes` to the current month's bucket. No-op for non-positive.
    func recordFileMinutes(_ minutes: Int)
}
