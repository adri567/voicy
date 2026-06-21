import SwiftData
import SwiftUI

struct TranscribeView: View {

    @State private var viewModel = TranscribeViewModel()
    @State private var historyFilter: TranscribeHistorySection.Filter = .all
    @State private var paywall: UpgradeContext?

    @Query(sort: \FileTranscriptionEntry.createdAt, order: .reverse)
    private var fileEntries: [FileTranscriptionEntry]

    private let rightColumnWidth: CGFloat = 340

    var body: some View {
        if let id = viewModel.detailEntryId, let entry = fileEntries.first(where: { $0.id == id }) {
            TranscribeDetailView(entry: entry, onBack: { viewModel.closeDetail() })
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                mastheadSection
                pipelineSection
                transcriptSection
                historySection
            }
        }
        .background(DS.Palette.paper)
        .paywall($paywall)
        .onChange(of: viewModel.fileLimitExceeded) { _, exceeded in
            if exceeded { paywall = .fileMinutes }
        }
    }

    // MARK: - Masthead

    @ViewBuilder
    private var mastheadSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TranscribeMasthead(
                selectedEngine: viewModel.selectedEngine,
                availableEngines: viewModel.availableEngines,
                onSelectEngine: { viewModel.selectEngine($0) },
                engineLabel: { viewModel.engineLabel(for: $0) },
                engineSubtitle: engineSubtitle,
                weeklyHoursLabel: viewModel.weeklyHoursLabel(from: fileEntries),
                weeklySessionsLabel: viewModel.weeklySessionsLabel(from: fileEntries)
            )
            .padding(.bottom, 30)

            SoftDivider()
                .padding(.bottom, 28)
        }
        .padding(.horizontal, DS.Spacing.pageHPadding)
        .padding(.top, DS.Spacing.pageTop)
    }

    private var engineSubtitle: String {
        switch viewModel.selectedEngine {
        case .whisper:
            "\(viewModel.engineDisplayName) · 99 languages · runs on-device · auto-detect available."
        case .parakeet:
            "\(viewModel.engineDisplayName) · 25 European languages + Japanese · runs on-device · manual language pick required."
        }
    }

    // MARK: - Pipeline

    @ViewBuilder
    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            TranscribePipelineHeader(modeLabel: viewModel.pipelineHeaderLabel)

            if let error = viewModel.processingError {
                errorBanner(error)
            }

            HStack(alignment: .top, spacing: 18) {
                leftPipelineCard
                    .frame(maxWidth: .infinity)
                TranscribeSettingsCard(
                    source: viewModel.sourceLanguage,
                    sourceOptions: viewModel.autoDetectAvailable
                        ? TranscribeLanguageCatalog.sourcesWithAuto
                        : TranscribeLanguageCatalog.allManual,
                    onSourceChange: { viewModel.setSourceLanguage(code: $0.code) },
                    showRerun: viewModel.fileURL != nil,
                    canRerun: viewModel.stage != .processing && viewModel.fileURL != nil,
                    onReRun: { viewModel.reRun() }
                )
                .frame(width: rightColumnWidth)
            }
        }
        .padding(.horizontal, DS.Spacing.pageHPadding)
        .padding(.bottom, 28)
    }

    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DS.Palette.accent)
            Text(message)
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink2)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button {
                viewModel.processingError = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(DS.Palette.ink3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Palette.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: DS.Radius.small))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.small)
                .stroke(DS.Palette.accent.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var leftPipelineCard: some View {
        switch viewModel.stage {
        case .idle:
            TranscribeDropZone { viewModel.startProcessing(url: $0) }
        case .processing:
            TranscribeProcessingPanel(
                fileMetadata: viewModel.fileMetadata,
                engineName: viewModel.engineDisplayName,
                sourceLabel: viewModel.sourceLanguage.native
            )
        case .done:
            if let metadata = viewModel.fileMetadata {
                TranscribeFilePlayer(
                    fileMetadata: metadata,
                    waveformBars: viewModel.realWaveform ?? [],
                    playhead: viewModel.playhead,
                    playing: viewModel.playing,
                    sourceLabel: viewModel.sourceLanguage.native,
                    onTogglePlay: { viewModel.togglePlay() },
                    onSeek: { viewModel.seek(to: $0) },
                    onReset: { viewModel.reset() }
                )
            }
        }
    }

    // MARK: - Transcript (latest run as PreviewCard)

    @ViewBuilder
    private var transcriptSection: some View {
        if viewModel.stage == .done, let metadata = viewModel.fileMetadata {
            VStack(alignment: .leading, spacing: 18) {
                latestHeader
                TranscribePreviewCard(
                    fileName: metadata.name,
                    durationLabel: metadata.durationLabel,
                    sourceCode: viewModel.sourceLanguage.code,
                    words: viewModel.wordCount,
                    segmentCount: viewModel.segments.count,
                    segments: viewModel.segments,
                    onOpen: { viewModel.openLatestDetail() }
                )
            }
            .padding(.horizontal, DS.Spacing.pageHPadding)
            .padding(.bottom, 36)
        }
    }

    @ViewBuilder
    private var latestHeader: some View {
        let prefix = Text("The ")
        let italic = Text("transcript").font(DS.Font.serifItalic(26))
        Text("\(prefix)\(italic)")
            .font(DS.Font.serif(26))
            .tracking(-0.3)
            .foregroundStyle(DS.Palette.ink2)
    }

    // MARK: - Earlier transcripts

    @ViewBuilder
    private var historySection: some View {
        let earlier = fileEntries.filter { $0.id != viewModel.latestEntryId }

        TranscribeHistorySection(
            entries: earlier,
            filter: $historyFilter,
            onOpen: { viewModel.openDetail(id: $0.id) }
        )
        .padding(.horizontal, DS.Spacing.pageHPadding)
        .padding(.bottom, 56)
    }
}
