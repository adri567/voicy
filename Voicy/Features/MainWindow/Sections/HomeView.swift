import AppKit
import SwiftData
import SwiftUI

struct HomeView: View {

    var viewModel: RecordingViewModel
    var onNavigate: (SidebarSection) -> Void

    @Query private var entries: [TranscriptionEntry]

    @State private var activeFilter: HistoryFilter = .all

    private static let historyWindowDays = 14

    init(viewModel: RecordingViewModel, onNavigate: @escaping (SidebarSection) -> Void) {
        self.viewModel = viewModel
        self.onNavigate = onNavigate
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.historyWindowDays, to: Date()) ?? .distantPast
        _entries = Query(
            filter: #Predicate<TranscriptionEntry> { $0.createdAt >= cutoff },
            sort: \.createdAt,
            order: .reverse
        )
    }

    private var filteredEntries: [TranscriptionEntry] {
        let cal = Calendar.current
        let now = Date()
        switch activeFilter {
        case .all:
            return entries
        case .today:
            return entries.filter { cal.isDateInToday($0.createdAt) }
        case .week:
            guard let weekStart = cal.date(byAdding: .day, value: -7, to: now) else { return entries }
            return entries.filter { $0.createdAt >= weekStart }
        case .whisper:
            return entries.filter { $0.engine == .whisper }
        case .parakeet:
            return entries.filter { $0.engine == .parakeet }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)
                    .padding(.bottom, 36)

                historySection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            heroBlock
                .frame(maxWidth: .infinity, alignment: .leading)

            statsPanel
                .frame(width: 320)
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "◆ The Lead", color: DS.Palette.accent)
                .padding(.bottom, 14)

            // Headline
            Text("Hey, your hands\nare already \(Text("resting.").italic().foregroundColor(DS.Palette.accent))")
                .font(DS.Font.serif(54))
                .tracking(-1.0)
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink)
                .padding(.bottom, 18)

            Text("Halte \(Text("Fn").font(DS.Font.mono(13, weight: .medium))) gedrückt und sprich. Beim Loslassen erscheint der Text dort, wo dein Cursor steht.")
                .font(DS.Font.sans(16))
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 28)
                .frame(maxWidth: 520, alignment: .leading)

            // Action row
            HStack(spacing: 14) {
                pillButton(
                    text: "Choose a model →",
                    filled: false
                ) {
                    onNavigate(.engine)
                }

                Text("\(engineDisplayName) · loaded")
                    .font(DS.Font.mono(11))
                    .foregroundStyle(DS.Palette.ink3)
            }
        }
    }

    private func pillButton(text: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(DS.Font.sans(13, weight: filled ? .semibold : .medium))
                .foregroundStyle(filled ? DS.Palette.paper : DS.Palette.ink)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(filled ? DS.Palette.ink : Color.clear)
                )
                .overlay(
                    Capsule().stroke(DS.Palette.ink, lineWidth: filled ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "By the numbers — today")
                .padding(.bottom, 18)

            StatRow(big: todayWords.formatted(), label: "words transcribed")
            StatRow(big: "\(wpm)", label: "avg. words / min")
            StatRow(big: "\(Int(todayMinutes))m", label: "hands stayed free")

            SoftDivider()
                .padding(.vertical, 18)

            MetaLabel(text: "Top destinations")
                .padding(.bottom, 10)

            let dests = topDestinations
            if dests.isEmpty {
                Text("Noch keine Ziel-Apps erfasst")
                    .font(DS.Font.sans(11))
                    .foregroundStyle(DS.Palette.ink3)
            } else {
                VStack(spacing: 6) {
                    ForEach(dests, id: \.name) { dest in
                        destRow(dest.name, dest.words, dest.pct)
                    }
                }
            }
        }
        .padding(26)
        .dsPanel()
    }

    private func destRow(_ name: String, _ count: Int, _ pct: Double) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 4)
                    Capsule()
                        .fill(DS.Palette.ink)
                        .frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(count)")
                .font(DS.Font.mono(10))
                .foregroundStyle(DS.Palette.ink3)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("The \(Text("Verlauf").italic().foregroundColor(DS.Palette.ink)) — a record of every word")
                    .font(DS.Font.serif(26))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink2)

                Spacer()
                FilterChips(active: $activeFilter)
            }
            .padding(.bottom, 20)

            if filteredEntries.isEmpty {
                emptyHistory
            } else {
                buckets
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .dsPanel()
            }

            HStack {
                MetaLabel(text: "\(filteredEntries.count) transcripts · last \(Self.historyWindowDays) days")
                Spacer()
            }
            .padding(.top, 24)
        }
    }

    private var emptyHistory: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(DS.Palette.ink3)
            Text("No transcripts yet — press \(Text("Fn").font(DS.Font.mono(13, weight: .medium))) to start.")
                .font(DS.Font.sans(14))
                .foregroundStyle(DS.Palette.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .dsPanel()
    }

    private var buckets: some View {
        let grouped = groupByDay(filteredEntries)
        return LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(grouped.enumerated()), id: \.offset) { idx, bucket in
                bucketHeader(bucket: bucket, first: idx == 0)
                    .padding(.top, idx == 0 ? 16 : 20)
                    .padding(.bottom, 6)

                ForEach(Array(bucket.entries.enumerated()), id: \.element.id) { itemIdx, entry in
                    HistoryRow(entry: entry, first: itemIdx == 0)
                }

                if idx != grouped.count - 1 {
                    SoftDivider()
                        .padding(.top, 20)
                }
            }
        }
    }

    private func bucketHeader(bucket: HistoryBucket, first: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bucket.title)
                    .font(DS.Font.serifItalic(22))
                    .foregroundStyle(DS.Palette.ink2)
                MetaLabel(text: bucket.subtitle)
            }
            Spacer()
        }
    }

    // MARK: - Derived data

    private var todayEntries: [TranscriptionEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.createdAt) }
    }

    private var todayWords: Int {
        todayEntries.map(\.text).reduce(0) { $0 + wordCount($1) }
    }

    private var todayMinutes: Double {
        todayEntries.reduce(0) { $0 + $1.duration } / 60.0
    }

    private var wpm: Int {
        guard todayMinutes > 0 else { return 0 }
        return Int(Double(todayWords) / todayMinutes)
    }

    private var engineDisplayName: String {
        switch TranscriptionEngine.current {
        case .whisper:
            switch DefaultTranscriptionService.activeModelID {
            case "openai_whisper-tiny":                     return "Whisper Tiny"
            case "openai_whisper-small":                    return "Whisper Small"
            case "openai_whisper-large-v3-v20240930_626MB": return "Whisper Large v3 Compact"
            case "openai_whisper-large-v3_947MB":           return "Whisper Large v3"
            default:                                         return "Whisper"
            }
        case .parakeet:
            switch ParakeetTranscriptionService.activeVersion {
            case "v3":         return "Parakeet v3"
            case "tdtCtc110m": return "Parakeet Lite"
            default:           return "Parakeet"
            }
        }
    }

    private var topDestinations: [(name: String, words: Int, pct: Double)] {
        let withTarget = entries.compactMap { entry -> (String, Int)? in
            guard let name = entry.targetAppName, !name.isEmpty else { return nil }
            return (name, wordCount(entry.text))
        }
        let summed = Dictionary(withTarget, uniquingKeysWith: +)
        let sorted = summed.sorted { $0.value > $1.value }.prefix(4)
        let max = sorted.first?.value ?? 0
        return sorted.map { (name: $0.key, words: $0.value, pct: max == 0 ? 0 : Double($0.value) / Double(max)) }
    }

    private func wordCount(_ s: String) -> Int {
        s.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

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

    private func groupByDay(_ list: [TranscriptionEntry]) -> [HistoryBucket] {
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
}

private struct HistoryBucket {
    let date: Date
    let title: String
    let subtitle: String
    let entries: [TranscriptionEntry]
}

private struct StatRow: View {
    let big: String
    let label: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(big)
                .font(DS.Font.serif(44))
                .foregroundStyle(DS.Palette.ink)
            Text(label)
                .font(DS.Font.sans(12))
                .foregroundStyle(DS.Palette.ink3)
        }
        .padding(.bottom, 14)
    }
}

enum HistoryFilter: CaseIterable, Hashable {
    case all, today, week, whisper, parakeet

    var label: String {
        switch self {
        case .all:      "ALL"
        case .today:    "TODAY"
        case .week:     "WEEK"
        case .whisper:  "WHISPER"
        case .parakeet: "PARAKEET"
        }
    }
}

private struct FilterChips: View {
    @Binding var active: HistoryFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button(action: { active = filter }) {
                    Text(filter.label)
                        .font(DS.Font.mono(10))
                        .tracking(1)
                        .foregroundStyle(active == filter ? DS.Palette.paper : DS.Palette.ink2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(active == filter ? DS.Palette.ink : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(active == filter ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: TranscriptionEntry
    let first: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                // Left: time + meta tags
                VStack(alignment: .leading, spacing: 8) {
                    Text(timeString)
                        .font(DS.Font.mono(18, weight: .medium))
                        .tracking(-0.2)
                        .foregroundStyle(DS.Palette.ink2)
                    HStack(spacing: 6) {
                        Text(entry.engine.shortLabel).dsTag()
                        Text(durationString).dsTag()
                    }
                }
                .frame(width: 140, alignment: .leading)

                // Middle: meta + text
                VStack(alignment: .leading, spacing: 6) {
                    metaLine
                    Text(entry.text)
                        .font(DS.Font.sans(15))
                        .foregroundStyle(DS.Palette.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: word count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(wordCount)")
                        .font(DS.Font.serif(26))
                        .tracking(-0.2)
                        .foregroundStyle(DS.Palette.ink3)
                    MetaLabel(text: "words")
                }
                .frame(width: 90, alignment: .trailing)
            }
            .padding(.vertical, 16)
        }
        .contextMenu {
            Button("Kopieren") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.text, forType: .string)
            }
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        if let appName = entry.targetAppName {
            HStack(spacing: 8) {
                Text("→")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.accent)
                Text(appName)
                    .font(DS.Font.mono(10, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(DS.Palette.ink2)
                if let title = entry.targetWindowTitle, !title.isEmpty {
                    Text("·")
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                    Text(title)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.ink3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        } else {
            MetaLabel(text: "Engine · \(entry.engine.displayName)")
        }
    }

    private var timeString: String {
        Self.timeFormatter.string(from: entry.createdAt)
    }

    private var durationString: String {
        let total = Int(entry.duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var wordCount: Int {
        entry.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}

private extension TranscriptionEngine {
    var shortLabel: String {
        switch self {
        case .whisper:  "WHISPER"
        case .parakeet: "PARAKEET"
        }
    }
}
