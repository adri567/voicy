import AppKit
import FactoryKit
import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

@Observable @MainActor
final class TranscribeViewModel {

    // MARK: - Injected services

    @ObservationIgnored @Injected(\.whisperTranscriptionService) private var whisperService
    @ObservationIgnored @Injected(\.parakeetTranscriptionService) private var parakeetService
    @ObservationIgnored @Injected(\.fileTranscriptionHistoryService) private var historyService
    @ObservationIgnored @Injected(\.diarizationService) private var diarizationService

    // MARK: - Engine + language selection (isolated from the global mic engine)

    /// Initial value mirrors the global mic engine, but after first read the
    /// two are independent. Swapping engines here never writes to UserDefaults.
    var selectedEngine: TranscriptionEngine = TranscriptionEngine.current

    /// `"auto"` triggers Whisper auto-detection. Hidden from the picker when
    /// Parakeet is active (Parakeet cannot auto-detect).
    var sourceLanguageCode: String = "de"

    // MARK: - Stage + processing state

    var stage: TranscribeStage = .idle
    var processingError: String?

    var fileURL: URL?
    var fileMetadata: TranscribeFileInfo?
    var realWaveform: [Double]?
    var realSegments: [TranscriptionSegment] = []

    /// ID of the just-completed run (the one shown as the PreviewCard).
    /// Used by the View to filter it out of the Earlier-transcripts list.
    var latestEntryId: UUID?

    /// `nil` = main page is shown. Otherwise = TranscriptDetail sub-view.
    var detailEntryId: UUID?

    // MARK: - Playback state (mirrors TranscribeAudioPlayer)

    var playhead: Double = 0
    var playing: Bool = false
    var copied: Bool = false

    @ObservationIgnored private let audioPlayer = TranscribeAudioPlayer()
    @ObservationIgnored private var playheadTask: Task<Void, Never>?
    @ObservationIgnored private var copiedResetTask: Task<Void, Never>?
    @ObservationIgnored private var processingTask: Task<Void, Never>?

    init() {}

    // MARK: - Computed values

    var availableEngines: [TranscriptionEngine] {
        TranscriptionEngine.allCases.filter { engine in
            switch engine {
            case .whisper:  whisperService.isModelInstalled()
            case .parakeet: parakeetService.isModelInstalled()
            }
        }
    }

    var selectedEngineInstalled: Bool {
        availableEngines.contains(selectedEngine)
    }

    var autoDetectAvailable: Bool {
        selectedEngine == .whisper
    }

    /// `nil` => Whisper auto-detect, else explicit ISO code.
    var effectiveSourceLanguage: String? {
        sourceLanguageCode == "auto" ? nil : sourceLanguageCode
    }

    var sourceLanguage: TranscribeLanguage {
        TranscribeLanguageCatalog.source(sourceLanguageCode)
    }

    var pipelineHeaderLabel: String {
        if sourceLanguageCode == "auto" {
            return "Transcribe · auto-detect"
        }
        return "Transcribe in \(sourceLanguage.native.uppercased())"
    }

    var segments: [TranscriptionSegment] { realSegments }

    var wordCount: Int {
        segments.reduce(0) { sum, seg in
            sum + seg.text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        }
    }

    var segmentSummary: String {
        guard !segments.isEmpty else { return "" }
        return "\(segments.count) segments · \(wordCount.formatted()) words"
    }

    // MARK: - Engine display

    var engineDisplayName: String {
        switch selectedEngine {
        case .whisper:  "Whisper"
        case .parakeet: "Parakeet"
        }
    }

    var engineModelLabel: String {
        switch selectedEngine {
        case .whisper:  whisperModelLabel(from: DefaultTranscriptionService.activeModelID)
        case .parakeet: "TDT v3"
        }
    }

    private func whisperModelLabel(from modelID: String) -> String {
        let bare = modelID
            .replacing("openai_whisper-", with: "")
            .replacing("distil-whisper_distil-", with: "")
        return bare.split(separator: "-").map { piece -> String in
            piece.prefix(1).uppercased() + piece.dropFirst()
        }.joined(separator: " ")
    }

    // MARK: - Stats (from FileTranscriptionEntry)

    func weeklyHoursLabel(from entries: [FileTranscriptionEntry]) -> String {
        let totalSeconds = weeklyEntries(entries).reduce(into: 0.0) { acc, entry in
            acc += entry.durationSeconds
        }
        if totalSeconds < 60 { return "0m" }
        if totalSeconds < 3600 {
            return "\(Int(totalSeconds / 60))m"
        }
        let hours = totalSeconds / 3600
        if hours >= 10 {
            return "\(Int(hours))h"
        }
        return "\(hours.formatted(.number.precision(.fractionLength(1))))h"
    }

    func weeklySessionsLabel(from entries: [FileTranscriptionEntry]) -> String {
        "\(weeklyEntries(entries).count)"
    }

    private func weeklyEntries(_ entries: [FileTranscriptionEntry]) -> [FileTranscriptionEntry] {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        return entries.filter { $0.createdAt >= cutoff }
    }

    // MARK: - Engine switching

    func selectEngine(_ engine: TranscriptionEngine) {
        guard engine != selectedEngine else { return }
        selectedEngine = engine
        // If Parakeet just got picked and source is auto, force a manual default.
        if !autoDetectAvailable, sourceLanguageCode == "auto" {
            sourceLanguageCode = "de"
        }
    }

    func setSourceLanguage(code: String) {
        sourceLanguageCode = code
    }

    // MARK: - Detail navigation

    func openDetail(id: UUID) {
        detailEntryId = id
    }

    func openLatestDetail() {
        if let id = latestEntryId {
            detailEntryId = id
        }
    }

    func closeDetail() {
        detailEntryId = nil
    }

    // MARK: - File drop / processing

    func startProcessing(url: URL) {
        cancelProcessing()
        resetPlayerState()
        processingError = nil
        fileURL = url
        stage = .processing

        processingTask = Task { [weak self] in
            guard let me = self else { return }
            do {
                try await me.runFullPipeline(url: url)
            } catch is CancellationError {
                // Swallow — caller already moved state forward.
            } catch {
                guard !Task.isCancelled else { return }
                me.processingError = error.localizedDescription
                me.stage = .idle
            }
        }
    }

    func reRun() {
        guard let url = fileURL else { return }
        startProcessing(url: url)
    }

    func reset() {
        cancelProcessing()
        resetPlayerState()
        audioPlayer.stop()
        fileURL = nil
        fileMetadata = nil
        realWaveform = nil
        realSegments = []
        latestEntryId = nil
        processingError = nil
        stage = .idle
    }

    private func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
    }

    private func resetPlayerState() {
        playheadTask?.cancel()
        playheadTask = nil
        playing = false
        playhead = 0
    }

    private func runFullPipeline(url: URL) async throws {
        // Metadata + waveform in parallel — both are independent of the
        // transcription engine call.
        async let metadata = TranscribeFileInfo.load(from: url)
        async let waveform = AudioWaveformReader.bars(for: url, count: 96)

        let (loadedMetadata, loadedWaveform) = try await (metadata, waveform)
        guard !Task.isCancelled else { return }

        fileMetadata = loadedMetadata
        realWaveform = loadedWaveform

        let service: any TranscriptionService = switch selectedEngine {
        case .whisper:  whisperService
        case .parakeet: parakeetService
        }

        // Diarization runs in parallel with the transcription. When the model
        // isn't installed we skip the diarize call entirely (no progress, no
        // latency hit). Errors are caught at the await site below — a failed
        // diarization must never block the transcription itself from showing.
        let shouldDiarize = diarizationService.isModelInstalled()
        async let diarizationFuture: [DiarizationSegment] = {
            guard shouldDiarize else { return [] }
            return (try? await diarizationService.diarize(at: url)) ?? []
        }()

        let result = try await service.transcribeFile(
            at: url,
            language: effectiveSourceLanguage
        )
        guard !Task.isCancelled else { return }

        let rawSegments = result.segments ?? [
            TranscriptionSegment(start: 0, end: result.duration, text: result.text)
        ]
        let diarization = await diarizationFuture
        let segments = Self.mergeSpeakers(into: rawSegments, diarization: diarization)
        realSegments = segments

        // Identify the language the transcript is actually in. Whisper supplies
        // it natively; for Parakeet we run NLLanguageRecognizer over the text.
        // If we have a confident detection, snap the picker to it so the UI
        // doesn't disagree with the result.
        let detected: String? = {
            if selectedEngine == .whisper, let whisperDetected = result.detectedLanguage {
                return whisperDetected
            }
            return LanguageDetector.detect(from: result.text)
        }()
        if let detected {
            sourceLanguageCode = detected
        }

        do {
            try audioPlayer.load(url: url)
        } catch {
            print("[Transcribe] AVAudioPlayer.load failed: \(error.localizedDescription)")
        }

        // Persist to file-history. Build the entry up front so we can capture
        // its ID for `latestEntryId` — needed by the UI to highlight (and
        // de-dupe) the current run.
        let storedLanguageCode = detected
            ?? (sourceLanguageCode == "auto" ? "en" : sourceLanguageCode)
        let entry = FileTranscriptionEntry(
            createdAt: .now,
            fileName: loadedMetadata.name,
            fileSizeBytes: loadedMetadata.sizeBytes,
            fileFormat: loadedMetadata.format,
            durationSeconds: loadedMetadata.durationSeconds > 0
                ? Double(loadedMetadata.durationSeconds)
                : result.duration,
            engine: selectedEngine,
            sourceLanguageCode: storedLanguageCode,
            fullText: result.text,
            segments: segments
        )
        latestEntryId = entry.id

        Task { [historyService] in
            do {
                try await historyService.save(entry)
            } catch {
                print("[Transcribe] history.save failed: \(error.localizedDescription)")
            }
        }

        stage = .done
    }

    // MARK: - Playback

    func togglePlay() {
        guard stage == .done else { return }
        if playing {
            audioPlayer.pause()
            playing = false
            playheadTask?.cancel()
            playheadTask = nil
        } else {
            audioPlayer.play()
            playing = true
            startPlayheadSync()
        }
    }

    func seek(to fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        playhead = clamped
        audioPlayer.seek(toFraction: clamped)
    }

    private func startPlayheadSync() {
        playheadTask?.cancel()
        playheadTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let me = self, me.playing else { break }
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, let me = self, me.playing else { return }
                me.playhead = me.audioPlayer.progress
                if !me.audioPlayer.isPlaying {
                    me.playing = false
                    break
                }
            }
        }
    }

    // MARK: - Transcript actions

    func copyAll() {
        let text = segments.map(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        copiedResetTask?.cancel()
        copiedResetTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1200))
            guard let self, !Task.isCancelled else { return }
            self.copied = false
        }
    }

    func downloadTxt() {
        let text = segments.map(\.text).joined(separator: "\n\n")
        guard !text.isEmpty else { return }
        let panel = NSSavePanel()
        let baseName = fileMetadata?.name.replacing(".m4a", with: "")
            .replacing(".mp3", with: "")
            .replacing(".wav", with: "")
            ?? "transcript"
        panel.nameFieldStringValue = "\(baseName).txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Speaker alignment

    /// Stamp each transcription segment with the speaker that has the most
    /// time overlap with it. Segments without any overlap stay as `nil` —
    /// they fall through to "no speaker info" in the UI.
    ///
    /// Pragmatic max-overlap heuristic — for very fast speaker switches
    /// within a single transcription segment the secondary speaker is lost,
    /// but Whisper / Parakeet segments are rarely <2s so the dominant
    /// speaker is the right call in practice.
    nonisolated static func mergeSpeakers(
        into segments: [TranscriptionSegment],
        diarization: [DiarizationSegment]
    ) -> [TranscriptionSegment] {
        guard !diarization.isEmpty else { return segments }

        return segments.map { seg in
            var bestSpeaker: Int?
            var bestOverlap: TimeInterval = 0
            for d in diarization {
                let overlap = max(0, min(seg.end, d.end) - max(seg.start, d.start))
                if overlap > bestOverlap {
                    bestOverlap = overlap
                    bestSpeaker = d.speakerId
                }
            }
            return TranscriptionSegment(
                start: seg.start,
                end: seg.end,
                text: seg.text,
                speaker: bestSpeaker
            )
        }
    }
}
