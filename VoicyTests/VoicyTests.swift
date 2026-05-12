import FactoryKit
import Testing
@testable import Voicy

@MainActor
@Suite("RecordingViewModel")
struct RecordingViewModelTests {

    init() {
        Container.shared.transcriptionService.register { MockTranscriptionService() }
        Container.shared.textCorrectionService.register { NoopTextCorrectionService() }
    }

    @Test("Startet im loadingModel-State")
    func initialState() {
        let viewModel = RecordingViewModel()
        #expect(viewModel.state == .loadingModel)
        #expect(viewModel.transcript.isEmpty)
    }

    @Test("Nach loadModel ist State idle")
    func loadModelSuccess() async throws {
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        #expect(viewModel.state == .idle)
    }

    @Test("Fehlgeschlagenes loadModel landet trotzdem im idle-State")
    func loadModelFailure() async {
        Container.shared.transcriptionService.register { FailingTranscriptionService() }
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        #expect(viewModel.state == .idle)
    }

    @Test("Toggle startet Aufnahme")
    func toggleStartsRecording() async {
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        #expect(viewModel.state == .recording)
    }

    @Test("Zweites Toggle stoppt und transkribiert")
    func toggleStopsAndTranscribes() async {
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()
        #expect(viewModel.state == .idle)
        #expect(viewModel.transcript == MockTranscriptionService.mockText)
    }

    @Test("Fehler beim Transkribieren landet im idle-State ohne Transcript")
    func transcriptionError() async {
        Container.shared.transcriptionService.register { FailingOnStopTranscriptionService() }
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()
        #expect(viewModel.state == .idle)
        #expect(viewModel.transcript.isEmpty)
    }
}

// MARK: - Mocks

final class MockTranscriptionService: TranscriptionService {
    static let mockText = "Hallo, das ist ein Test."

    nonisolated init() {}
    nonisolated func loadModel() async throws {}
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
        TranscriptionResult(text: Self.mockText, duration: 1.5)
    }
    nonisolated func currentAudioLevel() -> Float { 0 }
}

final class FailingTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws { throw TestError.loadFailed }
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.loadFailed
    }
    nonisolated func currentAudioLevel() -> Float { 0 }
}

final class FailingOnStopTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws {}
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.transcriptionFailed
    }
    nonisolated func currentAudioLevel() -> Float { 0 }
}

final class NoopTextCorrectionService: TextCorrectionService {
    nonisolated init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(_ text: String) async throws -> String { text }
}

enum TestError: Error {
    case loadFailed
    case transcriptionFailed
}
