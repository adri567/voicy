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
    }

    @ObservationIgnored
    @Injected(\.transcriptionService) private var service

    private(set) var state: RecordingState = .loadingModel
    private(set) var transcript: String = ""
    private(set) var audioLevel: Float = 0
    var showTranscript: Bool = UserDefaults.standard.bool(forKey: "dev.showTranscript")

    @ObservationIgnored private var levelTask: Task<Void, Never>?

    var isOverlayVisible: Bool {
        switch state {
        case .recording, .transcribing: true
        case .idle: !transcript.isEmpty
        case .loadingModel: false
        }
    }

    var menuBarIconName: String {
        switch state {
        case .loadingModel:  "arrow.down.circle.dotted"
        case .idle:          "waveform.and.mic"
        case .recording:     "waveform"
        case .transcribing:  "ellipsis.bubble"
        }
    }

    func onAppear() async {
        guard state == .loadingModel else { return }
        do {
            try await service.loadModel()
            state = .idle
        } catch {
            state = .idle
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
        case .loadingModel, .transcribing:
            break
        }
    }

    func toggleShowTranscript() {
        showTranscript.toggle()
        UserDefaults.standard.set(showTranscript, forKey: "dev.showTranscript")
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
        } catch {}
    }

    private func stopAndTranscribe() async {
        levelTask?.cancel()
        levelTask = nil
        audioLevel = 0
        state = .transcribing
        do {
            let result = try await service.stopAndTranscribe()
            transcript = result.text
            state = .idle
        } catch {
            state = .idle
        }
    }
}
