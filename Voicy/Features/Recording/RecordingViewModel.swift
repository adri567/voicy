import FactoryKit
import Foundation
import OSLog
import Observation

@Observable @MainActor
final class RecordingViewModel {

    enum RecordingState: Equatable {
        case loadingModel
        case idle
        case recording
        case transcribing
        case correcting
        case noModel
        case noBrain
        case limitReached
    }

    /// Resolved fresh on every access. We deliberately do *not* use
    /// `@Injected`, which would cache the service picked at ViewModel-init
    /// time — i.e. before the user has chosen an engine in onboarding. This
    /// way `TranscriptionEngine.current` is re-read whenever we need the
    /// service, so a Whisper→Parakeet switch (or vice versa) is picked up
    /// without an app relaunch.
    private var service: any TranscriptionService {
        Container.shared.transcriptionService()
    }

    @ObservationIgnored
    @Injected(\.textCorrectionService) private var correctionService

    @ObservationIgnored
    @Injected(\.transcriptionHistoryService) private var historyService

    @ObservationIgnored
    @Injected(\.modeCycleService) private var modeCycle

    @ObservationIgnored
    @Injected(\.snippetService) private var snippetService

    /// Constructor-injected (defaulting to the Factory registrations) so unit
    /// tests can pass mocks directly without racing other suites over the global
    /// container — the same pattern SelectionViewModel uses.
    @ObservationIgnored
    private let entitlement: any EntitlementService
    @ObservationIgnored
    private let usageTracking: any UsageTrackingService
    @ObservationIgnored
    private let telemetry: any TelemetryService

    init(
        entitlement: any EntitlementService = Container.shared.entitlementService(),
        usageTracking: any UsageTrackingService = Container.shared.usageTrackingService(),
        telemetry: any TelemetryService = Container.shared.telemetryService()
    ) {
        self.entitlement = entitlement
        self.usageTracking = usageTracking
        self.telemetry = telemetry
    }

    private(set) var state: RecordingState = .loadingModel
    private(set) var transcript: String = ""
    private(set) var audioLevel: Float = 0
    private(set) var correctionModelProgress: Double? = nil
    var showTranscript: Bool = UserDefaults.standard.bool(forKey: Preferences.Key.showTranscript)

    /// Disk check — true if any supported brain has its files cached. Also
    /// promotes a fallback brain to "active" if the previous active was wiped
    /// (or never set) but another one is on disk. Cheap enough to call on
    /// every render; not reactive on install-while-running.
    var isBrainInstalled: Bool {
        correctionService.ensureModelAvailable()
    }

    @ObservationIgnored private var levelTask: Task<Void, Never>?
    @ObservationIgnored private var pendingTargetApp: TargetAppSnapshot?

    /// Flipped to true when the user releases the hotkey before a recording
    /// session has actually started (i.e. while we're still inside the
    /// `startRecording` async pipeline waiting on `loadModel`). Each `await`
    /// resumption point in `startRecording` re-checks this and bails — without
    /// it, the bubble could flip to .recording *after* the user has let go.
    @ObservationIgnored private var startCanceled: Bool = false

    /// Guards against re-entering `startRecording` while a previous invocation
    /// is still suspended (most commonly inside `await service.loadModel()`).
    /// Without this, a second press during model load would reset
    /// `startCanceled` and let the orphaned first invocation finish into
    /// `.recording`, leaving the bubble stranded.
    @ObservationIgnored private var startInProgress: Bool = false

    func captureTargetApp(_ snapshot: TargetAppSnapshot?) {
        pendingTargetApp = snapshot
    }

    /// Drops any previously-loaded model state and re-runs `onAppear`. Used
    /// after onboarding finishes — at that point the engine may have just
    /// switched and a model that wasn't on disk at launch is now installed.
    func reloadActiveModel() async {
        state = .loadingModel
        await onAppear()
    }

    func onAppear() async {
        guard state == .loadingModel else { return }
        do {
            try await service.loadModel()
        } catch {
            Log.recording.error("RecordingViewModel: model loading failed: \(String(describing: error), privacy: .public)")
            telemetry.capture(error, context: ["stage": "loadModel"])
        }
        state = .idle
        Task { @MainActor [weak self] in
            guard let self else { return }
            correctionModelProgress = 0
            try? await correctionService.loadModel { [weak self] fraction in
                Task { @MainActor [weak self] in
                    self?.correctionModelProgress = fraction
                }
            }
            correctionModelProgress = nil
        }
    }

    func toggleRecording() async {
        switch state {
        case .idle where transcript.isEmpty:
            await startRecording()
        case .recording:
            await stopAndTranscribe()
        case .idle:
            clearTranscript()
        case .noModel, .noBrain, .limitReached:
            // Re-check on next press — user may have installed a model or the
            // rolling window may have freed up capacity since.
            await startRecording()
        case .loadingModel, .transcribing, .correcting:
            break
        }
    }

    func toggleShowTranscript() {
        showTranscript.toggle()
        UserDefaults.standard.set(showTranscript, forKey: Preferences.Key.showTranscript)
    }

    func clearTranscript() {
        transcript = ""
    }

    /// Stops the mic without running ASR. Used by the double-tap detector
    /// when the user's first tap is too short to be a real hold — likely
    /// the first half of a double-tap that should arm toggle mode. Returns
    /// fast (no Whisper/Parakeet inference) so `state` flips back to
    /// `.idle` before the user's second tap arrives.
    func discardRecording() async {
        guard state == .recording else { return }
        levelTask?.cancel()
        levelTask = nil
        audioLevel = 0
        await service.cancelRecording()
        pendingTargetApp = nil
        state = .idle
    }

    private func startRecording() async {
        guard !startInProgress else { return }
        startInProgress = true
        defer { startInProgress = false }
        startCanceled = false
        telemetry.breadcrumb("recording start", category: .recording)

        // Pre-flight: a Free user who's reached the weekly word allowance can't
        // start a new dictation. A recording already in flight is never
        // interrupted — only new starts are blocked.
        if wordLimitReached {
            showLimitReachedHint()
            return
        }

        // Pre-flight: nothing to record into if there's no voice model yet.
        guard service.isModelInstalled() else {
            showNoModelHint()
            return
        }
        // No-brain check happens at stop-time — the user picks the mode
        // mid-recording via fn+arrow, so the active mode at start is always raw.

        // First attempt — works when the model is already in RAM.
        do {
            try await service.startRecording()
            if await bailIfCanceled() { return }
            beginLevelTracking()
            state = .recording
            return
        } catch TranscriptionError.modelNotLoaded {
            // Files are on disk but the engine hasn't loaded them yet
            // (e.g. user just finished onboarding without restarting the app).
            // Fall through to the lazy-load path below.
        } catch {
            Log.recording.error("RecordingViewModel: start recording failed: \(String(describing: error), privacy: .public)")
            telemetry.capture(error, context: ["stage": "startRecording"])
            return
        }

        state = .loadingModel
        do {
            try await service.loadModel()
            if await bailIfCanceled() { return }
            try await service.startRecording()
            if await bailIfCanceled() { return }
            beginLevelTracking()
            state = .recording
        } catch {
            Log.recording.error("RecordingViewModel: lazy load + start failed: \(String(describing: error), privacy: .public)")
            telemetry.capture(error, context: ["stage": "startRecording.lazyLoad"])
            showNoModelHint()
        }
    }

    /// Returns true (and tears down anything we started) if the user
    /// released the hotkey while we were suspended in the start pipeline.
    private func bailIfCanceled() async -> Bool {
        guard startCanceled else { return false }
        await service.cancelRecording()
        state = .idle
        return true
    }

    /// Called by AppCoordinator when the user releases the hotkey while we
    /// are still in the `startRecording` pipeline (state == .loadingModel
    /// after a `modelNotLoaded` retry). Sets a flag the pipeline checks at
    /// every resumption point, and flips the UI back to idle immediately so
    /// the bubble doesn't visibly hang on a now-orphaned load.
    func cancelStartIfPending() {
        guard state == .loadingModel else { return }
        startCanceled = true
        state = .idle
    }

    /// Runs the LLM correction with a lazy-load fallback: if the brain hasn't
    /// been pulled into RAM yet (common right after install / after promoting
    /// a fallback active key), load it and retry once.
    private func runCorrection(text: String, mode: Mode, sourceLanguage: AppLanguage) async -> String? {
        telemetry.breadcrumb("correction start mode=\(mode.type.rawValue)", category: .correction)
        do {
            return try await correctionService.correct(text, mode: mode, sourceLanguage: sourceLanguage)
        } catch TextCorrectionError.modelNotLoaded {
            do {
                try await correctionService.loadModel()
                return try await correctionService.correct(text, mode: mode, sourceLanguage: sourceLanguage)
            } catch {
                Log.recording.error("RecordingViewModel: brain lazy-load + correct failed: \(String(describing: error), privacy: .public)")
                telemetry.capture(error, context: ["stage": "correction.lazyLoad", "mode": mode.type.rawValue])
                return nil
            }
        } catch {
            Log.recording.error("RecordingViewModel: correction failed: \(String(describing: error), privacy: .public)")
            telemetry.capture(error, context: ["stage": "correction", "mode": mode.type.rawValue])
            return nil
        }
    }

    private func beginLevelTracking() {
        levelTask?.cancel()
        levelTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let raw = await self.service.currentAudioLevel()
                self.audioLevel = self.audioLevel * 0.7 + raw * 0.3
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
    }

    @ObservationIgnored private var noModelDismissTask: Task<Void, Never>?

    private func showNoModelHint() {
        scheduleDismiss(to: .noModel)
    }

    private func showNoBrainHint() {
        scheduleDismiss(to: .noBrain)
    }

    private func showLimitReachedHint() {
        scheduleDismiss(to: .limitReached)
    }

    /// True when a Free user has reached the rolling weekly word allowance.
    /// Pro (a `nil` limit) never trips this.
    private var wordLimitReached: Bool {
        guard let limit = entitlement.weeklyWordLimit else { return false }
        return usageTracking.wordsUsedLast7Days() >= limit
    }

    private func scheduleDismiss(to errorState: RecordingState) {
        state = errorState
        noModelDismissTask?.cancel()
        noModelDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.4))
            guard let self, !Task.isCancelled, self.state == errorState else { return }
            self.state = .idle
        }
    }

    private func stopAndTranscribe() async {
        levelTask?.cancel()
        levelTask = nil
        audioLevel = 0
        let mode = modeCycle.activeMode
        let sourceLanguage = modeCycle.sourceLanguage
        telemetry.breadcrumb("recording stop mode=\(mode.type.rawValue)", category: .recording)
        state = .transcribing
        await Task.yield()
        do {
            let result = try await service.stopAndTranscribe(language: sourceLanguage.code)
            var didCorrect = false
            var brainMissing = false
            var finalText = result.text
            // Raw mode pastes the transcription verbatim. Snippets mode runs
            // a deterministic string-replace pass (no LLM, no brain check).
            // Every other mode hits the correction service for type-specific
            // prompting (translate/developer/email/custom). If the user is in
            // an AI mode but no brain is installed yet, we degrade gracefully:
            // the raw transcription still gets pasted, and the overlay flashes
            // a "No AI model installed" hint so they know polishing was skipped.
            if mode.type == .snippets, !result.text.isEmpty {
                finalText = await snippetService.apply(to: result.text)
            } else if mode.type != .raw, !result.text.isEmpty {
                if correctionService.ensureModelAvailable() {
                    state = .correcting
                    if let corrected = await runCorrection(text: result.text,
                                                           mode: mode,
                                                           sourceLanguage: sourceLanguage) {
                        finalText = corrected
                        didCorrect = true
                    }
                } else {
                    brainMissing = true
                }
            }
            transcript = finalText
            if brainMissing {
                showNoBrainHint()
            } else {
                state = .idle
            }
            if !finalText.isEmpty {
                // Book the pasted words against the rolling window. Skipped for
                // Pro (unlimited) so we don't write counters we never read.
                if entitlement.weeklyWordLimit != nil {
                    usageTracking.recordWords(finalText.wordCount)
                }
                let engine = TranscriptionEngine.current
                let target = pendingTargetApp
                pendingTargetApp = nil
                try? await historyService.save(
                    text: finalText,
                    duration: result.duration,
                    engine: engine,
                    corrected: didCorrect,
                    target: target
                )
            }
        } catch {
            Log.recording.error("RecordingViewModel: transcription failed: \(String(describing: error), privacy: .public)")
            telemetry.capture(error, context: ["stage": "transcribe"])
            state = .idle
        }
    }
}
