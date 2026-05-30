import Testing
@testable import Voicy

@MainActor
@Suite("SelectionViewModel")
struct SelectionViewModelTests {

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

    @Test("handleTap is a no-op and leaves state untouched")
    func handleTapIsNoOp() {
        let mock = MockSelectionService()
        let viewModel = SelectionViewModel(selectionService: mock)
        viewModel.handleTap()
        #expect(viewModel.hasSelection == false)
        #expect(viewModel.selectedText.isEmpty)
    }

    /// Runs `action`, then suspends until the view model has applied the next
    /// selection update — deterministic, no timing assumptions. Relies on the
    /// `onSelectionChange` hook the coordinator normally uses.
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
}
