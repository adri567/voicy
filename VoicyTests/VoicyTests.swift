import FactoryKit
import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("RecordingViewModel")
struct RecordingViewModelTests {

    init() {
        // Reset any modes-reel that prior tests may have written, otherwise
        // the new ModeCycleService picks up state from a previous test class.
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Preferences.Key.modesReel)
        defaults.removeObject(forKey: Preferences.Key.sourceLanguageCode)

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
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String { text }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}
}

actor RecordingTextCorrectionSpy: TextCorrectionService {
    private(set) var lastSource: AppLanguage?
    private(set) var lastMode: Mode?
    private(set) var callCount = 0

    init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String {
        await record(mode: mode, source: sourceLanguage)
        return text + " [\(mode.type.rawValue)]"
    }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}

    private func record(mode: Mode, source: AppLanguage) {
        callCount += 1
        lastMode = mode
        lastSource = source
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

// MARK: - ModeCycleService

@MainActor
@Suite("ModeCycleService", .serialized)
struct ModeCycleServiceTests {

    private func clearDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Preferences.Key.modesReel)
        defaults.removeObject(forKey: Preferences.Key.sourceLanguageCode)
    }

    @Test("Default-Reel: 4 Slots, step=0, Source=de")
    func defaultReel() {
        clearDefaults()
        let service = ModeCycleService()
        #expect(service.modes.count == 4)
        #expect(service.step == 0)
        #expect(service.sourceLanguage.code == "de")
        #expect(service.modes[0].type == .raw)
        #expect(service.modes[1].type == .translate)
        #expect(service.modes[2].type == .translate)
        #expect(service.modes[3].type == .email)
    }

    @Test("cycleForward wrappt vom letzten Slot zu 0")
    func cycleForwardWraps() {
        clearDefaults()
        let service = ModeCycleService()
        service.setStep(service.modes.count - 1)
        service.cycleForward()
        #expect(service.step == 0)
    }

    @Test("cycleBackward wrappt von 0 zum letzten Slot")
    func cycleBackwardWraps() {
        clearDefaults()
        let service = ModeCycleService()
        service.setStep(0)
        service.cycleBackward()
        #expect(service.step == service.modes.count - 1)
    }

    @Test("addMode: clamped bei maxSlots")
    func addModeClampedAtMax() {
        clearDefaults()
        let service = ModeCycleService()
        while service.modes.count < ModeCycleService.maxSlots {
            _ = service.addMode()
        }
        #expect(service.modes.count == ModeCycleService.maxSlots)
        let attempt = service.addMode()
        #expect(attempt == nil)
        #expect(service.modes.count == ModeCycleService.maxSlots)
    }

    @Test("removeMode: kann alle non-raw Slots entfernen, Raw bleibt")
    func removeModeDownToRawOnly() {
        clearDefaults()
        let service = ModeCycleService()
        #expect(service.modes.count == 4)
        // Remove every non-zero slot, repeatedly grabbing the new slot 1.
        while service.modes.count > 1 {
            let id = service.modes[1].id
            service.removeMode(id: id)
        }
        #expect(service.modes.count == ModeCycleService.minSlots)
        #expect(service.modes[0].type == .raw)
    }

    @Test("move: tauscht Positionen und step folgt")
    func moveReorders() {
        clearDefaults()
        let service = ModeCycleService()
        let originalSecond = service.modes[1].id
        service.setStep(1)
        service.move(id: originalSecond, by: 1)
        #expect(service.modes[2].id == originalSecond)
        #expect(service.step == 2)
    }

    @Test("update mutates only the given slot")
    func updateMutates() {
        clearDefaults()
        let service = ModeCycleService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "es" }
        #expect(service.modes[1].targetCode == "es")
        // Other slots unchanged
        #expect(service.modes[0].type == .raw)
    }

    @Test("setSourceLanguage: Translate-Slots mit target==newSource werden remapped")
    func setSourceLanguageReconcilesTargets() {
        clearDefaults()
        let service = ModeCycleService()
        // Force a translate slot to target English.
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "en" }
        // Now switch source to English — the slot must remap to something else.
        service.setSourceLanguage("en")
        #expect(service.sourceLanguage.code == "en")
        #expect(service.modes[1].targetCode != "en")
    }

    @Test("Persistence: nach setSourceLanguage liest neuer Service den Wert")
    func sourcePersists() {
        clearDefaults()
        let service = ModeCycleService()
        service.setSourceLanguage("es")
        let next = ModeCycleService()
        #expect(next.sourceLanguage.code == "es")
    }

    @Test("Persistence: nach update wird Reel persisted")
    func modesPersist() {
        clearDefaults()
        let service = ModeCycleService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "it" }
        let next = ModeCycleService()
        #expect(next.modes[1].targetCode == "it")
    }

    @Test("Slot 0: Type kann nicht via update geändert werden")
    func slot0TypeLocked() {
        clearDefaults()
        let service = ModeCycleService()
        let id = service.modes[0].id
        service.update(id: id) { $0.type = .email }
        #expect(service.modes[0].type == .raw)
    }

    @Test("Slot 0: removeMode wird ignoriert")
    func slot0RemoveBlocked() {
        clearDefaults()
        let service = ModeCycleService()
        // Add a 5th slot so we're above minSlots and the min-clamp doesn't
        // mask the slot-0-lock behaviour.
        _ = service.addMode()
        let countBefore = service.modes.count
        let id = service.modes[0].id
        service.removeMode(id: id)
        #expect(service.modes.count == countBefore)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 0: move wird ignoriert")
    func slot0MoveBlocked() {
        clearDefaults()
        let service = ModeCycleService()
        let id = service.modes[0].id
        service.move(id: id, by: 1)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 1: move(by: -1) verschiebt nicht in slot 0")
    func cannotDisplaceSlot0() {
        clearDefaults()
        let service = ModeCycleService()
        let slot0 = service.modes[0].id
        let slot1 = service.modes[1].id
        service.move(id: slot1, by: -1)
        // Slot 0 stays put. Slot 1 still at index 1.
        #expect(service.modes[0].id == slot0)
        #expect(service.modes[1].id == slot1)
    }
}

@Suite("SnippetService — normalize")
struct SnippetNormalizeTests {

    @Test("Lowercases")
    func lowercases() {
        #expect(DefaultSnippetService.normalize("Best Regards") == "best regards")
    }

    @Test("Dashes become spaces")
    func dashesBecomeSpaces() {
        #expect(DefaultSnippetService.normalize("E-Mail") == "e mail")
        #expect(DefaultSnippetService.normalize("E—Mail") == "e mail")
    }

    @Test("Multiple spaces collapsed")
    func multiSpaces() {
        #expect(DefaultSnippetService.normalize("hi    there") == "hi there")
    }

    @Test("Trailing whitespace stripped, leading kept (caller's job)")
    func trailingStripped() {
        #expect(DefaultSnippetService.normalize("hello   ") == "hello")
    }

    @Test("Leading dash does not produce leading space")
    func leadingDashNoLeadingSpace() {
        #expect(DefaultSnippetService.normalize("-Mail") == "mail")
        #expect(DefaultSnippetService.normalize("—Mail") == "mail")
    }
}

@Suite("SnippetService — applyReplacements")
struct SnippetApplyTests {

    private func snippet(_ triggers: [String], _ replacement: String, enabled: Bool = true) -> SnippetDTO {
        SnippetDTO(
            id: UUID(),
            triggers: triggers,
            replacement: replacement,
            enabled: enabled,
            createdAt: Date()
        )
    }

    @Test("Single match in middle of sentence")
    func singleMatch() {
        let result = DefaultSnippetService.applyReplacements(
            text: "vielen dank und best regards an alle",
            snippets: [snippet(["best regards"], "Beste Grüße, Adrian")]
        )
        #expect(result == "vielen dank und Beste Grüße, Adrian an alle")
    }

    @Test("Two different triggers in one sentence")
    func twoDifferentTriggers() {
        let result = DefaultSnippetService.applyReplacements(
            text: "schick es an meine email, best regards",
            snippets: [
                snippet(["meine email"], "adrian@example.com"),
                snippet(["best regards"], "Beste Grüße, Adrian")
            ]
        )
        #expect(result == "schick es an adrian@example.com, Beste Grüße, Adrian")
    }

    @Test("Same trigger twice — both replaced")
    func sameTriggerTwice() {
        let result = DefaultSnippetService.applyReplacements(
            text: "sende eine email, ich antworte per email",
            snippets: [snippet(["email"], "E-Mail")]
        )
        #expect(result == "sende eine E-Mail, ich antworte per E-Mail")
    }

    @Test("Case-insensitive matching")
    func caseInsensitive() {
        let result = DefaultSnippetService.applyReplacements(
            text: "Best Regards everyone",
            snippets: [snippet(["best regards"], "Beste Grüße")]
        )
        #expect(result == "Beste Grüße everyone")
    }

    @Test("Word boundary prevents mid-word match")
    func wordBoundary() {
        let result = DefaultSnippetService.applyReplacements(
            text: "bestseller list",
            snippets: [snippet(["best"], "BEST")]
        )
        #expect(result == "bestseller list")
    }

    @Test("Longest trigger wins on overlap")
    func longestWins() {
        let result = DefaultSnippetService.applyReplacements(
            text: "meine email",
            snippets: [
                snippet(["email"], "E-Mail"),
                snippet(["meine email"], "adrian@example.com")
            ]
        )
        #expect(result == "adrian@example.com")
    }

    @Test("Shorter trigger still matches when alone")
    func shorterAloneStillMatches() {
        let result = DefaultSnippetService.applyReplacements(
            text: "email",
            snippets: [
                snippet(["email"], "E-Mail"),
                snippet(["meine email"], "adrian@example.com")
            ]
        )
        #expect(result == "E-Mail")
    }

    @Test("Trigger followed by punctuation matches, punctuation preserved")
    func trailingPunctuationPreserved() {
        let result = DefaultSnippetService.applyReplacements(
            text: "best regards.",
            snippets: [snippet(["best regards"], "Beste Grüße, Adrian")]
        )
        // The trigger matches (word-boundary on the right is satisfied by '.'),
        // and the period stays as the speaker's terminal punctuation.
        #expect(result == "Beste Grüße, Adrian.")
    }

    @Test("Dash-and-space variants normalize equivalently")
    func dashSpaceVariants() {
        let s = [snippet(["e mail"], "E-Mail-Adresse")]
        #expect(DefaultSnippetService.applyReplacements(text: "meine E-Mail", snippets: s) == "meine E-Mail-Adresse")
        #expect(DefaultSnippetService.applyReplacements(text: "meine E Mail", snippets: s) == "meine E-Mail-Adresse")
        // "email" (without space or dash) is intentionally NOT matched —
        // user must add it as an explicit alias.
        #expect(DefaultSnippetService.applyReplacements(text: "meine email", snippets: s) == "meine email")
    }

    @Test("Adding an alias bridges the zero-space case")
    func aliasBridgesZeroSpace() {
        let s = [snippet(["e mail", "email"], "E-Mail-Adresse")]
        #expect(DefaultSnippetService.applyReplacements(text: "meine email", snippets: s) == "meine E-Mail-Adresse")
    }

    @Test("Multiple aliases — any trigger matches same replacement")
    func aliasesMatch() {
        let s = snippet(["best regards", "kind regards", "regards"], "Beste Grüße")
        #expect(DefaultSnippetService.applyReplacements(text: "kind regards", snippets: [s]) == "Beste Grüße")
        #expect(DefaultSnippetService.applyReplacements(text: "regards everyone", snippets: [s]) == "Beste Grüße everyone")
    }

    @Test("Empty input returns empty")
    func emptyInput() {
        let result = DefaultSnippetService.applyReplacements(
            text: "",
            snippets: [snippet(["x"], "y")]
        )
        #expect(result.isEmpty)
    }

    @Test("No matches leaves text untouched")
    func noMatches() {
        let result = DefaultSnippetService.applyReplacements(
            text: "hallo welt",
            snippets: [snippet(["foo"], "bar")]
        )
        #expect(result == "hallo welt")
    }

    @Test("Leftmost-longest on true overlap")
    func leftmostLongest() {
        // "email best" and "best regards" overlap on the word "best".
        // Longer ("best regards" = 12 chars vs "email best" = 10 chars) wins;
        // leftmost only matters on length tie.
        let result = DefaultSnippetService.applyReplacements(
            text: "email best regards",
            snippets: [
                snippet(["email best"], "X"),
                snippet(["best regards"], "Y")
            ]
        )
        // Longest is "best regards" (12), so Y wins; "email " stays untouched.
        #expect(result == "email Y")
    }
}
