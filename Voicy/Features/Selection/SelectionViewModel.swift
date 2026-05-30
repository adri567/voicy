import FactoryKit
import Foundation
import OSLog

/// Owns the current selection state for the selection-action pill and exposes
/// the (currently no-op) tap action. Consumes `SelectionService.selectionChanges`
/// and notifies the coordinator via `onSelectionChange` so it can show/hide the
/// floating panel.
@Observable
@MainActor
final class SelectionViewModel {

    private(set) var hasSelection = false
    /// Retained for upcoming transform features; unused by the MVP view.
    private(set) var selectedText = ""

    /// Called after every selection update so the owner (AppCoordinator) can
    /// drive the panel. Keeps window orchestration out of the view model.
    @ObservationIgnored
    var onSelectionChange: (() -> Void)?

    @ObservationIgnored
    private let selectionService: any SelectionService

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?

    /// Constructor injection (defaulting to the Factory registration) keeps the
    /// view model decoupled from the shared container, so unit tests can pass a
    /// mock directly without racing other suites over global registration.
    init(selectionService: any SelectionService = Container.shared.selectionService()) {
        self.selectionService = selectionService
    }

    /// Starts the service and begins consuming its selection stream. Idempotent.
    func start() {
        guard observationTask == nil else { return }
        selectionService.start()
        observationTask = Task { [weak self] in
            guard let self else { return }
            for await state in self.selectionService.selectionChanges {
                self.apply(state)
            }
        }
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
        selectionService.stop()
    }

    /// No-op for the MVP — wired up to the rewrite/proofread flow in a later step.
    func handleTap() {
        Log.app.debug("Selection action tapped (no-op)")
    }

    private func apply(_ state: SelectionState) {
        hasSelection = state.hasSelection
        selectedText = state.selectedText
        onSelectionChange?()
    }

    isolated deinit {
        observationTask?.cancel()
    }
}
