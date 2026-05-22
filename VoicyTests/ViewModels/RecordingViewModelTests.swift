import FactoryKit
import Testing
@testable import Voicy

@MainActor
@Suite("RecordingViewModel", .serialized)
struct RecordingViewModelTests {

    init() {
        // Reset any modes-reel that prior tests may have written, otherwise
        // the new ModeCycleService picks up state from a previous test class.
        clearModeCycleDefaults()

        Container.shared.transcriptionService.register { MockTranscriptionService() }
        Container.shared.textCorrectionService.register { NoopTextCorrectionService() }
        Container.shared.transcriptionHistoryService.register { NoopTranscriptionHistoryService() }
        Container.shared.modeCycleService.register {
            MainActor.assumeIsolated { ModeCycleService() }
        }
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

    @Test("Raw-Mode: kein LLM-Call, Transcript ist der ASR-Rohtext")
    func rawModeSkipsLLM() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.modeCycleService()
        cycle.setStep(0) // default reel starts with .raw

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.callCount == 0)
        #expect(viewModel.transcript == MockTranscriptionService.mockText)
    }

    @Test("Translate-Mode: LLM mit mode + sourceLanguage aufgerufen")
    func translateModeCallsLLM() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.modeCycleService()
        cycle.setSourceLanguage("de")
        // Default reel slot 1 is .translate; force it to target French.
        let translateID = cycle.modes[1].id
        cycle.update(id: translateID) { $0.targetCode = "fr" }
        cycle.setStep(1)

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.callCount == 1)
        #expect(await spy.lastMode?.type == .translate)
        #expect(await spy.lastMode?.targetCode == "fr")
        #expect(await spy.lastSource?.code == "de")
    }

    @Test("Developer-Mode: LLM mit type .developer aufgerufen")
    func developerModeCallsLLM() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.modeCycleService()
        let id = cycle.modes[1].id
        cycle.update(id: id) { $0.type = .developer }
        cycle.setStep(1)

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.lastMode?.type == .developer)
    }

    @Test("Custom-Mode: prompt wird durchgereicht")
    func customModePassesPrompt() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.modeCycleService()
        let id = cycle.modes[1].id
        cycle.update(id: id) { slot in
            slot.type = .custom
            slot.name = "Slack reply"
            slot.emoji = "💬"
            slot.prompt = "Rewrite as a short Slack message."
        }
        cycle.setStep(1)

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.lastMode?.type == .custom)
        #expect(await spy.lastMode?.prompt == "Rewrite as a short Slack message.")
    }
}
