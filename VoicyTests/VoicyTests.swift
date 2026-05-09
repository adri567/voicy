import FactoryKit
import Testing
@testable import Voicy

@MainActor
@Suite("RecordingViewModel")
struct RecordingViewModelTests {

    init() {
        Container.shared.transcriptionService.register { MockTranscriptionService() }
    }

    @Test("Startet im loadingModel-State")
    func initialState() {
        let viewModel = RecordingViewModel()
        #expect(viewModel.state == .loadingModel)
        #expect(viewModel.transcript.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Nach loadModel ist State idle")
    func loadModelSuccess() async throws {
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        #expect(viewModel.state == .idle)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("loadModel setzt errorMessage bei Fehler")
    func loadModelFailure() async {
        Container.shared.transcriptionService.register { FailingTranscriptionService() }
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        #expect(viewModel.errorMessage != nil)
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

    @Test("Fehler beim Transkribieren setzt errorMessage")
    func transcriptionError() async {
        Container.shared.transcriptionService.register { FailingOnStopTranscriptionService() }
        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()
        #expect(viewModel.state == .idle)
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - Mocks

final class MockTranscriptionService: TranscriptionService, @unchecked Sendable {
    static let mockText = "Hallo, das ist ein Test."

    func loadModel() async throws {}
    func startRecording() async throws {}
    func stopAndTranscribe() async throws -> TranscriptionResult {
        TranscriptionResult(text: Self.mockText, duration: 1.5)
    }
}

final class FailingTranscriptionService: TranscriptionService, @unchecked Sendable {
    func loadModel() async throws { throw TestError.loadFailed }
    func startRecording() async throws {}
    func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.loadFailed
    }
}

final class FailingOnStopTranscriptionService: TranscriptionService, @unchecked Sendable {
    func loadModel() async throws {}
    func startRecording() async throws {}
    func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.transcriptionFailed
    }
}

enum TestError: Error {
    case loadFailed
    case transcriptionFailed
}
