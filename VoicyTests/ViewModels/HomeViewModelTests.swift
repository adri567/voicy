import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {

    private func entry(
        text: String = "one two three",
        daysAgo: Int = 0,
        duration: TimeInterval = 60,
        engine: TranscriptionEngine = .whisper,
        target: String? = nil
    ) -> TranscriptionEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let e = TranscriptionEntry(
            text: text,
            createdAt: date,
            duration: duration,
            engine: engine,
            corrected: false,
            target: nil
        )
        e.targetAppName = target
        return e
    }

    @Test("filter .all returns every entry")
    func filterAll() {
        let vm = HomeViewModel()
        vm.filter = .all
        #expect(vm.filtered([entry(daysAgo: 0), entry(daysAgo: 10)]).count == 2)
    }

    @Test("filter .today returns only today's entries")
    func filterToday() {
        let vm = HomeViewModel()
        vm.filter = .today
        #expect(vm.filtered([entry(daysAgo: 0), entry(daysAgo: 2)]).count == 1)
    }

    @Test("filter .week returns entries within the last 7 days")
    func filterWeek() {
        let vm = HomeViewModel()
        vm.filter = .week
        #expect(vm.filtered([entry(daysAgo: 3), entry(daysAgo: 10)]).count == 1)
    }

    @Test("todayWords sums word counts of today's entries only")
    func todayWords() {
        let vm = HomeViewModel()
        let entries = [
            entry(text: "one two three", daysAgo: 0),
            entry(text: "four five", daysAgo: 0),
            entry(text: "skip me later", daysAgo: 5)
        ]
        #expect(vm.todayWords(from: entries) == 5)
    }

    @Test("todayMinutes sums durations expressed in minutes")
    func todayMinutes() {
        let vm = HomeViewModel()
        let entries = [entry(daysAgo: 0, duration: 60), entry(daysAgo: 0, duration: 30)]
        #expect(vm.todayMinutes(from: entries) == 1.5)
    }

    @Test("wpm is words per minute, zero when there is no audio")
    func wpm() {
        let vm = HomeViewModel()
        // 6 words across 120 seconds (2 minutes) → 3 wpm.
        let entries = [
            entry(text: "a b c", daysAgo: 0, duration: 60),
            entry(text: "d e f", daysAgo: 0, duration: 60)
        ]
        #expect(vm.wpm(from: entries) == 3)
        #expect(vm.wpm(from: []) == 0)
    }

    @Test("topDestinations groups by target app and ranks by total words")
    func topDestinations() {
        let vm = HomeViewModel()
        let entries = [
            entry(text: "one two three", target: "Mail"),  // 3
            entry(text: "four five", target: "Mail"),       // 2 → Mail = 5
            entry(text: "six", target: "Slack"),            // 1
            entry(text: "no target here", target: nil)
        ]
        let result = vm.topDestinations(from: entries)
        #expect(result.count == 2)
        #expect(result[0].name == "Mail")
        #expect(result[0].words == 5)
        #expect(result[0].pct == 1.0)
        #expect(result[1].name == "Slack")
    }

    @Test("groupByDay labels today and yesterday and groups entries")
    func groupByDay() {
        let vm = HomeViewModel()
        let entries = [entry(daysAgo: 0), entry(daysAgo: 1), entry(daysAgo: 1)]
        let buckets = vm.groupByDay(entries)
        #expect(buckets.count == 2)
        #expect(buckets[0].title == "Today")
        #expect(buckets[0].entries.count == 1)
        #expect(buckets[1].title == "Yesterday")
        #expect(buckets[1].entries.count == 2)
    }
}
