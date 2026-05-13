import FactoryKit
import Foundation
import Observation

@Observable
final class RecordingViewModel {

    enum RecordingState: Equatable {
        case loadingModel
        case idle
        case recording
        case transcribing
        case correcting
    }

    @ObservationIgnored
    @Injected(\.transcriptionService) private var service

    @ObservationIgnored
    @Injected(\.textCorrectionService) private var correctionService

    @ObservationIgnored
    @Injected(\.transcriptionHistoryService) private var historyService

    @ObservationIgnored
    @Injected(\.languageCycleService) private var languageCycle

    private(set) var state: RecordingState = .loadingModel
    private(set) var transcript: String = ""
    private(set) var audioLevel: Float = 0
    private(set) var correctionModelProgress: Double? = nil
    var showTranscript: Bool = UserDefaults.standard.bool(forKey: Preferences.Key.showTranscript)

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
        do {
            try await service.startRecording()
            state = .recording
            levelTask = Task { @MainActor [weak self] in
                while !Task.isCancelled {
                    guard let self else { return }
                    let raw = self.service.currentAudioLevel()
                    self.audioLevel = self.audioLevel * 0.7 + raw * 0.3
                    try? await Task.sleep(for: .milliseconds(60))
                }
            }
        } catch {
            print("[RecordingViewModel] Start recording failed: \(error)")
        }
    }

    private func stopAndTranscribe() async {
        levelTask?.cancel()
        levelTask = nil
        audioLevel = 0
        let sourceLanguage = languageCycle.source
        let targetLanguage = languageCycle.activeTarget
        state = .transcribing
        await Task.yield()
        do {
            let result = try await service.stopAndTranscribe()
            var didCorrect = false
            var finalText = result.text
            // LLM only runs when a translation target is active. Step 0 (source
            // language) returns the raw ASR transcript untouched.
            if targetLanguage != nil, !result.text.isEmpty {
                state = .correcting
                if let corrected = try? await correctionService.correct(
                    result.text,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                ) {
                    finalText = corrected
                    didCorrect = true
                }
            }
            transcript = finalText
            state = .idle
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
