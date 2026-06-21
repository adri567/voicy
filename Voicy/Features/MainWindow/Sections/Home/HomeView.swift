import AppKit
import SwiftData
import SwiftUI

struct HomeView: View {

    var recordingViewModel: RecordingViewModel
    var onNavigate: (SidebarSection) -> Void

    @Query private var entries: [TranscriptionEntry]
    @State private var viewModel = HomeViewModel()
    @State private var paywall: UpgradeContext?

    init(viewModel: RecordingViewModel, onNavigate: @escaping (SidebarSection) -> Void) {
        self.recordingViewModel = viewModel
        self.onNavigate = onNavigate
        let cutoff = HomeViewModel.queryCutoffDate
        _entries = Query(
            filter: #Predicate<TranscriptionEntry> { $0.createdAt >= cutoff },
            sort: \.createdAt,
            order: .reverse
        )
    }

    private var filteredEntries: [TranscriptionEntry] { viewModel.filtered(entries) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)
                    .padding(.bottom, 36)

                if let quota = viewModel.wordQuota {
                    WordQuotaCard(quota: quota) { paywall = .wordLimit }
                        .padding(.horizontal, DS.Spacing.pageHPadding)
                        .padding(.bottom, 36)
                }

                historySection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
        .paywall($paywall)
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

            Text("Hey, your hands\nare already \(Text("resting.").italic().foregroundColor(DS.Palette.accent))")
                .font(DS.Font.serif(54))
                .tracking(-1.0)
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Hold")
                        .font(DS.Font.sans(16))
                        .foregroundStyle(DS.Palette.ink2)
                    Kbd("Fn", highlighted: true)
                    Text("and start talking.")
                        .font(DS.Font.sans(16))
                        .foregroundStyle(DS.Palette.ink2)
                }
                Text("When you let go, your words land wherever the cursor is.")
                    .font(DS.Font.sans(16))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 520, alignment: .leading)
            }
            .padding(.bottom, 28)

            HStack(spacing: 14) {
                pillButton(text: "Choose a model →", filled: false) {
                    onNavigate(.engine)
                }

                Text("\(viewModel.engineDisplayName) · loaded")
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
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "By the numbers — today")
                .padding(.bottom, 18)

            StatRow(big: viewModel.todayWords(from: entries).formatted(), label: "words transcribed")
            StatRow(big: "\(viewModel.wpm(from: entries))", label: "avg. words / min")
            StatRow(big: "\(Int(viewModel.todayMinutes(from: entries)))m", label: "hands stayed free")

            SoftDivider()
                .padding(.vertical, 18)

            MetaLabel(text: "Top destinations")
                .padding(.bottom, 10)

            let dests = viewModel.topDestinations(from: entries)
            if dests.isEmpty {
                Text("No target apps yet")
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
                Text("The \(Text("history").italic().foregroundColor(DS.Palette.ink)) — a record of every word")
                    .font(DS.Font.serif(26))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink2)

                Spacer()
                HistoryFilterChips(active: $viewModel.filter)
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
                MetaLabel(text: "\(filteredEntries.count) transcripts · last \(HomeViewModel.historyWindowDays) days")
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
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("No transcripts yet — press")
                    .font(DS.Font.sans(14))
                    .foregroundStyle(DS.Palette.ink3)
                Kbd("Fn", highlighted: true)
                Text("to start.")
                    .font(DS.Font.sans(14))
                    .foregroundStyle(DS.Palette.ink3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .dsPanel()
    }

    private var buckets: some View {
        let grouped = viewModel.groupByDay(filteredEntries)
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
}
