import Testing
@testable import Voicy

@MainActor
@Suite("SelectionViewModel")
struct SelectionViewModelTests {

    // MARK: - Selection observation

    @Test("start() starts the underlying service")
    func startStartsService() {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        viewModel.start()
        #expect(mock.startCount == 1)
        viewModel.stop()
    }

    @Test("start() is idempotent")
    func startIsIdempotent() {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        viewModel.start()
        viewModel.start()
        #expect(mock.startCount == 1)
        viewModel.stop()
    }

    @Test("stop() stops the underlying service")
    func stopStopsService() {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        viewModel.start()
        viewModel.stop()
        #expect(mock.stopCount == 1)
    }

    @Test("Reflects an incoming selection")
    func reflectsSelection() async {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        await onNextChange(of: viewModel) {
            viewModel.start()
            mock.send(SelectionState(hasSelection: true, selectedText: "hello"))
        }
        #expect(viewModel.hasSelection)
        #expect(viewModel.selectedText == "hello")
        viewModel.stop()
    }

    @Test("Clears when the selection goes away")
    func clearsSelection() async {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        await onNextChange(of: viewModel) {
            viewModel.start()
            mock.send(SelectionState(hasSelection: true, selectedText: "hello"))
        }
        await onNextChange(of: viewModel) {
            mock.send(.none)
        }
        #expect(viewModel.hasSelection == false)
        #expect(viewModel.selectedText.isEmpty)
        viewModel.stop()
    }

    @Test("Dismissing hides the pill until the selection changes")
    func dismissHidesUntilSelectionChanges() async {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        await onNextChange(of: viewModel) {
            viewModel.start()
            mock.send(SelectionState(hasSelection: true, selectedText: "hello"))
        }
        #expect(viewModel.hasSelection)

        // User pressed Fn to dictate instead of acting on the selection.
        viewModel.dismissCurrentSelection()
        #expect(viewModel.hasSelection == false)

        // The same selection keeps arriving from polling — stays hidden.
        await onNextChange(of: viewModel) {
            mock.send(SelectionState(hasSelection: true, selectedText: "hello"))
        }
        #expect(viewModel.hasSelection == false)

        // A different selection brings the pill back.
        await onNextChange(of: viewModel) {
            mock.send(SelectionState(hasSelection: true, selectedText: "world"))
        }
        #expect(viewModel.hasSelection)
        viewModel.stop()
    }

    // MARK: - Action flow (proofread + rephrase share the path)

    @Test("run with no live selection does nothing", arguments: SelectionAction.allCases)
    func runNoSelection(action: SelectionAction) {
        let selection = MockSelectionService()  // stubbedSelection defaults to .none
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService()
        )
        viewModel.run(action)
        #expect(viewModel.phase == .idle)
        #expect(viewModel.runningAction == nil)
        #expect(selection.writtenText == nil)
    }

    @Test("No brain shows a failure hint on the tapped action", arguments: SelectionAction.allCases)
    func noBrainShowsFailure(action: SelectionAction) {
        let selection = selecting("hello")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(available: false)
        )
        viewModel.run(action)
        #expect(viewModel.phase == .failed)
        #expect(viewModel.runningAction == action)
        #expect(selection.writtenText == nil)
        viewModel.stop()
    }

    @Test("Successful transform writes the result back via AX", arguments: SelectionAction.allCases)
    func writesBack(action: SelectionAction) async {
        let selection = selecting("helo")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .success("hello"))
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(action) }
        #expect(selection.writtenText == "hello")
        #expect(viewModel.phase == .idle)
        #expect(viewModel.runningAction == nil)
        #expect(viewModel.isWorking == false)
    }

    @Test("Falls back to paste when AX set fails", arguments: SelectionAction.allCases)
    func fallsBackToPaste(action: SelectionAction) async {
        let selection = selecting("helo")
        selection.setSelectedTextSucceeds = false
        let paste = MockPasteService()
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .success("hello")),
            pasteService: paste
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(action) }
        #expect(paste.pasted == ["hello"])
    }

    @Test("Unchanged result writes nothing back", arguments: SelectionAction.allCases)
    func unchangedDoesNotWrite(action: SelectionAction) async {
        let selection = selecting("hello")
        let paste = MockPasteService()
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .echo),
            pasteService: paste
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(action) }
        #expect(selection.writtenText == nil)
        #expect(paste.pasted.isEmpty)
    }

    @Test("Transform error shows a failure hint", arguments: SelectionAction.allCases)
    func errorShowsFailure(action: SelectionAction) async {
        let selection = selecting("hello")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .failure)
        )
        await onPhase(.failed, of: viewModel) { viewModel.run(action) }
        #expect(viewModel.runningAction == action)
        #expect(selection.writtenText == nil)
    }

    @Test("Transform error is reported to telemetry", arguments: SelectionAction.allCases)
    func errorReportsTelemetry(action: SelectionAction) async {
        let selection = selecting("hello")
        let spy = SpyTelemetryService()
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .failure),
            telemetry: spy
        )
        await onPhase(.failed, of: viewModel) { viewModel.run(action) }
        #expect(spy.capturedStages().contains("selection"))
    }

    @Test("A hanging brain times out into a failure hint")
    func timeoutShowsFailure() async {
        let selection = selecting("hello")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .hang),
            inferenceTimeout: .milliseconds(50)
        )
        await onPhase(.failed, of: viewModel) { viewModel.run(.rephrase) }
        #expect(selection.writtenText == nil)
    }

    @Test("Model loading does not count against the inference timeout")
    func loadingDoesNotTimeOut() async {
        let selection = selecting("helo")
        // Load is slower than the inference timeout; only inference is timed, so
        // this must still succeed rather than show the failure hint.
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(
                outcome: .success("hello"),
                loadDelay: .milliseconds(120)
            ),
            inferenceTimeout: .milliseconds(40)
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(.proofread) }
        #expect(selection.writtenText == "hello")
    }

    @Test("A second action is ignored while one is working")
    func secondActionIgnoredWhileWorking() async {
        let selection = selecting("hello")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .hang),
            inferenceTimeout: .seconds(60)
        )
        await onPhase(.working, of: viewModel) { viewModel.run(.proofread) }
        #expect(viewModel.isWorking)
        viewModel.run(.rephrase)  // ignored: already working
        #expect(viewModel.runningAction == .proofread)
        #expect(viewModel.phase == .working)
        viewModel.stop()
    }

    // MARK: - Word-limit gating (shared budget with dictation)

    @Test("Free over limit: blocks, calls onUpgradeNeeded, writes nothing", arguments: SelectionAction.allCases)
    func freeOverLimitBlocks(action: SelectionAction) async {
        let selection = selecting("hello")
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .success("fixed")),
            entitlement: MockEntitlementService(plan: .free),
            usageTracking: MockUsageTrackingService(words: PlanLimits.freeWeeklyWords)
        )
        var upgradeAsked = false
        viewModel.onUpgradeNeeded = { upgradeAsked = true }
        await onPhase(.failed, of: viewModel) { viewModel.run(action) }
        #expect(upgradeAsked)
        #expect(selection.writtenText == nil)
        viewModel.stop()
    }

    @Test("Free under limit: books the written words")
    func freeUnderLimitBooksWords() async {
        let selection = selecting("helo")
        let usage = MockUsageTrackingService(words: 5)
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .success("hello there")),
            entitlement: MockEntitlementService(plan: .free),
            usageTracking: usage
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(.proofread) }
        #expect(selection.writtenText == "hello there")
        #expect(usage.words == 5 + "hello there".wordCount)
    }

    @Test("Pro: never blocked, books nothing")
    func proBooksNothing() async {
        let selection = selecting("helo")
        let usage = MockUsageTrackingService(words: 999_999)
        let viewModel = SelectionViewModel(
            selectionService: selection,
            correctionService: StubTextCorrectionService(outcome: .success("hello")),
            entitlement: MockEntitlementService(plan: .pro),
            usageTracking: usage
        )
        await onPhase(.idle, of: viewModel) { viewModel.run(.proofread) }
        #expect(selection.writtenText == "hello")
        #expect(usage.words == 999_999)  // unchanged — Pro isn't metered
    }

    // MARK: - Helpers

    private func selecting(_ text: String) -> MockSelectionService {
        let mock = MockSelectionService()
        mock.stubbedSelection = SelectionState(hasSelection: true, selectedText: text)
        return mock
    }

    /// Runs `action`, then suspends until the view model has applied the next
    /// selection update — deterministic, no timing assumptions.
    private func onNextChange(
        of viewModel: SelectionViewModel,
        _ action: () -> Void
    ) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            viewModel.onSelectionChange = { continuation.resume() }
            action()
        }
        viewModel.onSelectionChange = nil
    }

    /// Runs `action`, then suspends until the view model reaches `target` phase.
    private func onPhase(
        _ target: SelectionActionPhase,
        of viewModel: SelectionViewModel,
        _ action: () -> Void
    ) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var resumed = false
            viewModel.onSelectionChange = {
                guard !resumed, viewModel.phase == target else { return }
                resumed = true
                continuation.resume()
            }
            action()
        }
        viewModel.onSelectionChange = nil
    }
}
