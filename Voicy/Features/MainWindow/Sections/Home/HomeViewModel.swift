import Foundation
import Observation

@Observable
final class HomeViewModel {

    /// Active history filter — bound from the FilterChips row.
    var filter: HistoryFilter = .all

    /// Sliding window in days for the SwiftData query. Computed by the View at
    /// init time (because @Query needs the predicate then), exposed here so the
    /// formatter caption can reuse it.
    static let historyWindowDays = 14

    /// Cutoff date used by the SwiftData predicate. The View reads this once
    /// during `init` so the @Query has a stable value.
    static var queryCutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -historyWindowDays, to: Date()) ?? .distantPast
    }

    // MARK: - Filtering

    /// Apply the current filter to the SwiftData-fetched entries.
    func filtered(_ entries: [TranscriptionEntry]) -> [TranscriptionEntry] {
        let cal = Calendar.current
        let now = Date()
        switch filter {
        case .all:
            return entries
        case .today:
            return entries.filter { cal.isDateInToday($0.createdAt) }
        case .week:
            guard let weekStart = cal.date(byAdding: .day, value: -7, to: now) else { return entries }
            return entries.filter { $0.createdAt >= weekStart }
        }
    }

    // MARK: - Stats (today)

    func todayEntries(from entries: [TranscriptionEntry]) -> [TranscriptionEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.createdAt) }
    }

    func todayWords(from entries: [TranscriptionEntry]) -> Int {
        todayEntries(from: entries).reduce(0) { $0 + $1.wordCount }
    }

    func todayMinutes(from entries: [TranscriptionEntry]) -> Double {
        todayEntries(from: entries).reduce(0) { $0 + $1.duration } / 60.0
    }

    func wpm(from entries: [TranscriptionEntry]) -> Int {
        let minutes = todayMinutes(from: entries)
        guard minutes > 0 else { return 0 }
        return Int(Double(todayWords(from: entries)) / minutes)
    }

    func topDestinations(from entries: [TranscriptionEntry]) -> [(name: String, words: Int, pct: Double)] {
        let withTarget = entries.compactMap { entry -> (String, Int)? in
            guard let name = entry.targetAppName, !name.isEmpty else { return nil }
            return (name, entry.wordCount)
        }
        let summed = Dictionary(withTarget, uniquingKeysWith: +)
        let sorted = summed.sorted { $0.value > $1.value }.prefix(4)
        let max = sorted.first?.value ?? 0
        return sorted.map { (name: $0.key, words: $0.value, pct: max == 0 ? 0 : Double($0.value) / Double(max)) }
    }

    // MARK: - Engine display

    var engineDisplayName: String {
        switch TranscriptionEngine.current {
        case .whisper:  ModelCatalog.engineName(forLibraryID: DefaultTranscriptionService.activeModelID)
        case .parakeet: ModelCatalog.engineName(forLibraryID: ParakeetTranscriptionService.activeVersion)
        }
    }

    // MARK: - Bucketing for the day-grouped history list

    func groupByDay(_ list: [TranscriptionEntry]) -> [HistoryBucket] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var byDay: [Date: [TranscriptionEntry]] = [:]
        for entry in list {
            let day = cal.startOfDay(for: entry.createdAt)
            byDay[day, default: []].append(entry)
        }

        return byDay.keys.sorted(by: >).map { day in
            let items = byDay[day]!
            let title: String
            let subtitle: String
            if cal.isDate(day, inSameDayAs: today) {
                title = "Today"
                subtitle = Self.weekdayFormatter.string(from: day).uppercased()
            } else if cal.isDate(day, inSameDayAs: yesterday) {
                title = "Yesterday"
                subtitle = Self.weekdayFormatter.string(from: day).uppercased()
            } else {
                title = Self.shortDayFormatter.string(from: day)
                subtitle = Self.yearFormatter.string(from: day)
            }
            return HistoryBucket(date: day, title: title, subtitle: subtitle, entries: items)
        }
    }

    // MARK: - Helpers

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private static let shortDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()
}
