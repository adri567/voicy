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
    private(set) var errorMessage: String?

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
            errorMessage = error.localizedDescription
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

    func clearTranscript() {
        transcript = ""
        errorMessage = nil
    }

    private func startRecording() async {
        do {
            try await service.startRecording()
            state = .recording
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopAndTranscribe() async {
        state = .transcribing
        do {
            let result = try await service.stopAndTranscribe()
            transcript = result.text
            state = .idle
        } catch {
            errorMessage = error.localizedDescription
            state = .idle
        }
    }
}


