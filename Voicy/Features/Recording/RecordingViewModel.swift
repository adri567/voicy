import FactoryKit
import Foundation
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
    }

    @ObservationIgnored
    @Injected(\.transcriptionService) private var service

    @ObservationIgnored
    @Injected(\.textCorrectionService) private var correctionService

    @ObservationIgnored
    @Injected(\.transcriptionHistoryService) private var historyService

    @ObservationIgnored
    @Injected(\.modeCycleService) private var modeCycle

    @ObservationIgnored
    @Injected(\.snippetService) private var snippetService

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
        MLXTextCorrectionService.ensureActiveBrainInstalled() != nil
    }

    @ObservationIgnored private var levelTask: Task<Void, Never>?
    @ObservationIgnored private var pendingTargetApp: TargetAppSnapshot?

    func captureTargetApp(_ snapshot: TargetAppSnapshot?) {
        pendingTargetApp = snapshot
    }

    func onAppear() async {
        guard state == .loadingModel else { return }
        do {
            try await service.loadModel()
        } catch {
            print("[RecordingViewModel] Model loading failed: \(error)")
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
        case .noModel, .noBrain:
            // Re-check on next press — user may have installed a model since.
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

    private func startRecording() async {
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
            beginLevelTracking()
            state = .recording
            return
        } catch TranscriptionError.modelNotLoaded {
            // Files are on disk but the engine hasn't loaded them yet
            // (e.g. user just finished onboarding without restarting the app).
            // Fall through to the lazy-load path below.
        } catch {
            print("[RecordingViewModel] Start recording failed: \(error)")
            return
        }

        state = .loadingModel
        do {
            try await service.loadModel()
            try await service.startRecording()
            beginLevelTracking()
            state = .recording
        } catch {
            print("[RecordingViewModel] Lazy load + start failed: \(error)")
            showNoModelHint()
        }
    }

    /// Runs the LLM correction with a lazy-load fallback: if the brain hasn't
    /// been pulled into RAM yet (common right after install / after promoting
    /// a fallback active key), load it and retry once.
    private func runCorrection(text: String, mode: Mode, sourceLanguage: AppLanguage) async -> String? {
        do {
            return try await correctionService.correct(text, mode: mode, sourceLanguage: sourceLanguage)
        } catch TextCorrectionError.modelNotLoaded {
            do {
                try await correctionService.loadModel()
                return try await correctionService.correct(text, mode: mode, sourceLanguage: sourceLanguage)
            } catch {
                print("[RecordingViewModel] Brain lazy-load + correct failed: \(error)")
                return nil
            }
        } catch {
            print("[RecordingViewModel] Correction failed: \(error)")
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
        state = .transcribing
        await Task.yield()
        do {
            let result = try await service.stopAndTranscribe()
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
                if MLXTextCorrectionService.ensureActiveBrainInstalled() != nil {
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
            print("[RecordingViewModel] Transcription failed: \(error)")
            state = .idle
        }
    }
}
