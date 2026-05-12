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

    private(set) var state: RecordingState = .loadingModel
    private(set) var transcript: String = ""
    private(set) var audioLevel: Float = 0
    private(set) var correctionModelProgress: Double? = nil
    var showTranscript: Bool = UserDefaults.standard.bool(forKey: Preferences.Key.showTranscript)
    var correctionEnabled: Bool = UserDefaults.standard.bool(forKey: Preferences.Key.correctionEnabled) {
        didSet { UserDefaults.standard.set(correctionEnabled, forKey: Preferences.Key.correctionEnabled) }
    }

    @ObservationIgnored private var levelTask: Task<Void, Never>?

    var menuBarIconName: String {
        switch state {
        case .loadingModel:              "arrow.down.circle.dotted"
        case .idle:                      "waveform.and.mic"
        case .recording:                 "waveform"
        case .transcribing, .correcting: "ellipsis.bubble"
        }
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
        UserDefaults.standard.set(showTranscript, forKey: "dev.showTranscript")
    }

    func toggleCorrection() {
        correctionEnabled.toggle()
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
        state = .transcribing
        await Task.yield()
        do {
            let result = try await service.stopAndTranscribe()
            if correctionEnabled && !result.text.isEmpty {
                state = .correcting
                let corrected = (try? await correctionService.correct(result.text)) ?? result.text
                transcript = corrected
            } else {
                transcript = result.text
            }
            state = .idle
        } catch {
            print("[RecordingViewModel] Transcription failed: \(error)")
            state = .idle
        }
    }
}
