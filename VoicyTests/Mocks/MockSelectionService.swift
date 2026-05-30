@testable import Voicy
import Foundation

/// Controllable `SelectionService` for tests: `send(_:)` pushes a state to
/// subscribers, and start/stop calls are counted. `@MainActor` to be `Sendable`
/// despite the call counters.
@MainActor
final class MockSelectionService: SelectionService {

    nonisolated let selectionChanges: AsyncStream<SelectionState>
    private nonisolated let continuation: AsyncStream<SelectionState>.Continuation

    private(set) var startCount = 0
    private(set) var stopCount = 0

    /// What `currentSelection()` returns (the live read at tap time).
    var stubbedSelection: SelectionState = .none
    /// Whether `setSelectedText(_:)` reports success (false → caller should fall
    /// back to paste).
    var setSelectedTextSucceeds = true
    /// Captures the text passed to `setSelectedText(_:)`.
    private(set) var writtenText: String?

    nonisolated init() {
        let (stream, continuation) = AsyncStream<SelectionState>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.selectionChanges = stream
        self.continuation = continuation
    }

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func currentSelection() -> SelectionState { stubbedSelection }

    func setSelectedText(_ text: String) -> Bool {
        writtenText = text
        return setSelectedTextSucceeds
    }

    /// Test hook: deliver a selection state to subscribers.
    func send(_ state: SelectionState) { continuation.yield(state) }
}
