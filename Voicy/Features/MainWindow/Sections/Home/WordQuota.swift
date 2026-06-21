import Foundation

/// Snapshot of the Free-tier rolling word allowance for display in the Home
/// quota card. Produced by `HomeViewModel`; `nil` for Pro (unmetered).
nonisolated struct WordQuota: Equatable {
    let used: Int
    let limit: Int

    /// 0...1, clamped — the bar never overfills even if usage briefly exceeds
    /// the cap (the last dictation that crossed the line still gets booked).
    var fraction: Double {
        guard limit > 0 else { return 0 }
        return min(1, Double(used) / Double(limit))
    }

    /// Remaining words, never negative.
    var remaining: Int { max(0, limit - used) }

    /// True once the allowance is spent — drives the card's "limit reached" tone.
    var isExhausted: Bool { used >= limit }

    /// Near the cap (≥80%) — the card warms up to nudge before the hard stop.
    var isNearLimit: Bool { fraction >= 0.8 }
}
