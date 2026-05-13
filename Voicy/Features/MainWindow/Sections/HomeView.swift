import AppKit
import SwiftData
import SwiftUI

struct HomeView: View {

    var viewModel: RecordingViewModel
    var onNavigate: (SidebarSection) -> Void

    @Query(sort: \TranscriptionEntry.createdAt, order: .reverse) private var entries: [TranscriptionEntry]

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
                FilterChips()
            }
            .padding(.bottom, 20)

            if entries.isEmpty {
                emptyHistory
            } else {
                buckets
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .dsPanel()
            }

            HStack {
                MetaLabel(text: "\(entries.count) transcripts total")
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
        let grouped = groupByDay(entries)
        return VStack(alignment: .leading, spacing: 0) {
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
        TranscriptionEngine.current.displayName
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

    private func groupByDay(_ list: [TranscriptionEntry]) -> [HistoryBucket] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let weekdayFmt = DateFormatter()
        weekdayFmt.dateFormat = "EEEE, MMMM d"
        let shortFmt = DateFormatter()
        shortFmt.dateFormat = "EEE, MMM d"

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
                subtitle = weekdayFmt.string(from: day).uppercased()
            } else if cal.isDate(day, inSameDayAs: yesterday) {
                title = "Yesterday"
                subtitle = weekdayFmt.string(from: day).uppercased()
            } else {
                title = shortFmt.string(from: day)
                let yearFmt = DateFormatter()
                yearFmt.dateFormat = "yyyy"
                subtitle = yearFmt.string(from: day)
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

private struct FilterChips: View {
    // MOCK: filtering is not wired yet. TODO(history-filter).
    @State private var active: String = "All"
    private let chips = ["All", "Pinned", "Whisper", "Parakeet"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(chips, id: \.self) { c in
                Button(action: { active = c }) {
                    Text(c.uppercased())
                        .font(DS.Font.mono(10))
                        .tracking(1)
                        .foregroundStyle(active == c ? DS.Palette.paper : DS.Palette.ink2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(active == c ? DS.Palette.ink : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(active == c ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HistoryRow: View {
    let entry: TranscriptionEntry
    let first: Bool

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
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: entry.createdAt)
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
