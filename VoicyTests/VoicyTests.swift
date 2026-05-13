import FactoryKit
import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("RecordingViewModel")
struct RecordingViewModelTests {

    init() {
        Container.shared.transcriptionService.register { MockTranscriptionService() }
        Container.shared.textCorrectionService.register { NoopTextCorrectionService() }
        Container.shared.transcriptionHistoryService.register { NoopTranscriptionHistoryService() }
        Container.shared.languageCycleService.register {
            MainActor.assumeIsolated { LanguageCycleService() }
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

    @Test("Step 0: kein LLM-Call, Transcript ist der ASR-Rohtext")
    func stepZeroSkipsLLM() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.languageCycleService()
        cycle.setSource("de")
        cycle.resetCycle()

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.callCount == 0)
        #expect(viewModel.transcript == MockTranscriptionService.mockText)
    }

    @Test("Mit aktivem Cycle-Target übersetzt: target wird durchgereicht")
    func correctionUsesActiveTargetWhenStepGreaterZero() async {
        let spy = RecordingTextCorrectionSpy()
        Container.shared.textCorrectionService.register { spy }
        let cycle = Container.shared.languageCycleService()
        cycle.setSource("de")
        cycle.setTarget(at: 0, code: "fr")
        cycle.setStep(1)

        let viewModel = RecordingViewModel()
        await viewModel.onAppear()
        await viewModel.toggleRecording()
        await viewModel.toggleRecording()

        #expect(await spy.lastSource?.code == "de")
        #expect(await spy.lastTarget?.code == "fr")
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
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}
}

final class FailingTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws { throw TestError.loadFailed }
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.loadFailed
    }
    nonisolated func currentAudioLevel() -> Float { 0 }
    nonisolated func isModelInstalled() -> Bool { false }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { throw TestError.loadFailed }
    nonisolated func removeModel() async throws {}
}

final class FailingOnStopTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws {}
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
        throw TestError.transcriptionFailed
    }
    nonisolated func currentAudioLevel() -> Float { 0 }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}
}

final class NoopTextCorrectionService: TextCorrectionService {
    nonisolated init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(
        _ text: String,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage?
    ) async throws -> String { text }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}
}

actor RecordingTextCorrectionSpy: TextCorrectionService {
    private(set) var lastSource: AppLanguage?
    private(set) var lastTarget: AppLanguage?
    private(set) var callCount = 0

    init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(
        _ text: String,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage?
    ) async throws -> String {
        await record(source: sourceLanguage, target: targetLanguage)
        return text + (targetLanguage.map { " [→\($0.code)]" } ?? " [cleaned]")
    }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}

    private func record(source: AppLanguage, target: AppLanguage?) {
        callCount += 1
        lastSource = source
        lastTarget = target
    }
}

final class NoopTranscriptionHistoryService: TranscriptionHistoryService {
    nonisolated init() {}
    nonisolated func save(
        text: String,
        duration: TimeInterval,
        engine: TranscriptionEngine,
        corrected: Bool,
        target: TargetAppSnapshot?
    ) async throws {}
}

enum TestError: Error {
    case loadFailed
    case transcriptionFailed
}

// MARK: - LanguageCycleService

@MainActor
@Suite("LanguageCycleService", .serialized)
struct LanguageCycleServiceTests {

    private func makeService(source: String, targets: [String?]) -> LanguageCycleService {
        let defaults = UserDefaults.standard
        defaults.set(source, forKey: Preferences.Key.languageSourceCode)
        let codes = targets.map { $0 ?? "" }
        defaults.set(codes, forKey: Preferences.Key.languageTargetCodes)
        return LanguageCycleService()
    }

    @Test("Default-Step ist 0, source ist aktiv, alle targets nil")
    func initialStateHasSourceActiveAndNoTargets() {
        let service = makeService(source: "de", targets: [nil, nil, nil])
        #expect(service.step == 0)
        #expect(service.activeLanguage.code == "de")
        #expect(service.activeTarget == nil)
        #expect(service.targets.allSatisfy { $0 == nil })
    }

    @Test("cycleForward bleibt bei 0 wenn keine Targets gesetzt sind")
    func cycleForwardNoOpWithoutTargets() {
        let service = makeService(source: "de", targets: [nil, nil, nil])
        service.cycleForward()
        #expect(service.step == 0)
    }

    @Test("cycleForward erhöht step bis zum letzten belegten Slot")
    func cycleForwardClampsAtLastFilled() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.cycleForward()
        #expect(service.step == 1)
        service.cycleForward()
        service.cycleForward()
        #expect(service.step == 3)
        service.cycleForward()
        #expect(service.step == 3)
        #expect(service.activeTarget?.code == "nl")
    }

    @Test("cycleForward überspringt leere Slots")
    func cycleForwardSkipsNilSlots() {
        let service = makeService(source: "de", targets: ["en", nil, "fr"])
        service.cycleForward()
        #expect(service.step == 1)
        #expect(service.activeTarget?.code == "en")
        service.cycleForward()
        #expect(service.step == 3)
        #expect(service.activeTarget?.code == "fr")
    }

    @Test("cycleBackward überspringt leere Slots")
    func cycleBackwardSkipsNilSlots() {
        let service = makeService(source: "de", targets: ["en", nil, "fr"])
        service.setStep(3)
        service.cycleBackward()
        #expect(service.step == 1)
        service.cycleBackward()
        #expect(service.step == 0)
    }

    @Test("setStep akzeptiert nur belegte Slots")
    func setStepRejectsEmptySlot() {
        let service = makeService(source: "de", targets: ["en", nil, nil])
        service.setStep(2)
        #expect(service.step == 0)
        service.setStep(1)
        #expect(service.step == 1)
    }

    @Test("setStep akzeptiert nur 0...3")
    func setStepRejectsOutOfRange() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.setStep(5)
        #expect(service.step == 0)
        service.setStep(-1)
        #expect(service.step == 0)
        service.setStep(2)
        #expect(service.step == 2)
    }

    @Test("setTarget ignoriert ungültigen Index")
    func setTargetIgnoresInvalidIndex() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.setTarget(at: 5, code: "es")
        #expect(service.targets.map { $0?.code } == ["en", "fr", "nl"])
    }

    @Test("clearTarget setzt Slot auf nil und resetCycled wenn aktiv")
    func clearTargetResetsCycleWhenActive() {
        let service = makeService(source: "de", targets: ["en", "fr", nil])
        service.setStep(2)
        service.clearTarget(at: 1)
        #expect(service.targets[1] == nil)
        #expect(service.step == 0)
    }

    @Test("clearTarget hält den Cycle wenn ein anderer Slot aktiv ist")
    func clearTargetKeepsCycleWhenOtherActive() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.setStep(1)
        service.clearTarget(at: 2)
        #expect(service.targets[2] == nil)
        #expect(service.step == 1)
    }

    @Test("setSource persistiert in UserDefaults")
    func setSourcePersists() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.setSource("es")
        let stored = UserDefaults.standard.string(forKey: Preferences.Key.languageSourceCode)
        #expect(stored == "es")
        #expect(service.source.code == "es")
    }

    @Test("setTarget persistiert in UserDefaults")
    func setTargetPersists() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.setTarget(at: 1, code: "it")
        let stored = UserDefaults.standard.stringArray(forKey: Preferences.Key.languageTargetCodes)
        #expect(stored == ["en", "it", "nl"])
    }

    @Test("clearTarget persistiert leeren String als nil-Marker")
    func clearTargetPersistsEmptyString() {
        let service = makeService(source: "de", targets: ["en", "fr", "nl"])
        service.clearTarget(at: 1)
        let stored = UserDefaults.standard.stringArray(forKey: Preferences.Key.languageTargetCodes)
        #expect(stored == ["en", "", "nl"])
    }

    @Test("Init liest leere Strings als nil-Slot")
    func initParsesEmptyStringsAsNil() {
        let service = makeService(source: "de", targets: ["en", nil, "fr"])
        #expect(service.targets.count == 3)
        #expect(service.targets[0]?.code == "en")
        #expect(service.targets[1] == nil)
        #expect(service.targets[2]?.code == "fr")
    }
}
