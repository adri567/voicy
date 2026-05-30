import FactoryKit
import Foundation
import OSLog

/// Owns the selection-action pill: tracks whether text is selected, runs the
/// proofread-and-replace flow on tap, and exposes the visual `phase`. Consumes
/// `SelectionService.selectionChanges` and notifies the coordinator via
/// `onSelectionChange` so it can show/hide the floating panel.
@Observable
@MainActor
final class SelectionViewModel {

    private(set) var hasSelection = false
    /// Retained for diagnostics/future use; the flow re-reads the live
    /// selection at tap time rather than trusting this polled value.
    private(set) var selectedText = ""
    private(set) var phase: SelectionActionPhase = .idle
    /// Which action is currently working, or last failed. Lets each button show
    /// the spinner/warning only on itself.
    private(set) var runningAction: SelectionAction?

    /// Called after every selection- or phase change so the owner
    /// (AppCoordinator) can re-evaluate panel visibility. Keeps window
    /// orchestration out of the view model.
    @ObservationIgnored
    var onSelectionChange: (() -> Void)?

    @ObservationIgnored
    private let selectionService: any SelectionService
    @ObservationIgnored
    private let correctionService: any TextCorrectionService
    @ObservationIgnored
    private let pasteService: any PasteService
    @ObservationIgnored
    private let proofreadTimeout: Duration

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?
    @ObservationIgnored
    private var actionTask: Task<Void, Never>?
    @ObservationIgnored
    private var failedResetTask: Task<Void, Never>?

    /// How long the failed-hint stays up before returning to idle.
    private static let failedHintDuration: Duration = .seconds(1.5)

    /// Constructor injection (defaulting to the Factory registrations) keeps the
    /// view model decoupled from the shared container, so unit tests can pass
    /// mocks directly without racing other suites over global registration.
    init(
        selectionService: any SelectionService = Container.shared.selectionService(),
        correctionService: any TextCorrectionService = Container.shared.textCorrectionService(),
        pasteService: any PasteService = Container.shared.pasteService(),
        proofreadTimeout: Duration = .seconds(30)
    ) {
        self.selectionService = selectionService
        self.correctionService = correctionService
        self.pasteService = pasteService
        self.proofreadTimeout = proofreadTimeout
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
        actionTask?.cancel()
        actionTask = nil
        failedResetTask?.cancel()
        failedResetTask = nil
        selectionService.stop()
    }

    /// Runs `action` on the live selection with the installed brain and writes
    /// the result back in place. No-ops if already working, nothing is selected,
    /// or no brain is installed (the latter shows a brief failure hint).
    func run(_ action: SelectionAction) {
        guard phase == .idle else { return }

        let original = selectionService.currentSelection().selectedText
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        guard correctionService.ensureModelAvailable() else {
            fail(action)
            return
        }

        runningAction = action
        setPhase(.working)
        let service = correctionService
        let timeout = proofreadTimeout
        actionTask = Task { [weak self] in
            do {
                let corrected = try await withTimeout(timeout) {
                    try await Self.transform(original, action: action, using: service)
                }
                guard let self, !Task.isCancelled else { return }
                self.applyCorrection(corrected, original: original)
            } catch is CancellationError {
                // Superseded/torn down — leave state as the canceller set it.
            } catch {
                Log.app.error("Selection \(String(describing: action), privacy: .public) failed: \(String(describing: error), privacy: .public)")
                self?.fail(action)
            }
        }
    }

    // MARK: - Private

    /// Runs the action's transform, lazily loading the brain into memory if it's
    /// on disk but not yet resident (mirrors `RecordingViewModel.runCorrection`).
    private nonisolated static func transform(
        _ text: String,
        action: SelectionAction,
        using service: any TextCorrectionService
    ) async throws -> String {
        do {
            return try await apply(action, to: text, using: service)
        } catch TextCorrectionError.modelNotLoaded {
            try await service.loadModel()
            return try await apply(action, to: text, using: service)
        }
    }

    private nonisolated static func apply(
        _ action: SelectionAction,
        to text: String,
        using service: any TextCorrectionService
    ) async throws -> String {
        switch action {
        case .proofread: try await service.proofread(text)
        case .rephrase:  try await service.rephrase(text)
        }
    }

    private func applyCorrection(_ corrected: String, original: String) {
        let trimmed = corrected.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, corrected != original else {
            finishIdle()
            return
        }
        if !selectionService.setSelectedText(corrected) {
            pasteService.paste(corrected)
        }
        finishIdle()
    }

    private func fail(_ action: SelectionAction) {
        runningAction = action
        setPhase(.failed)
        failedResetTask?.cancel()
        failedResetTask = Task { [weak self] in
            try? await Task.sleep(for: Self.failedHintDuration)
            guard let self, !Task.isCancelled, self.phase == .failed else { return }
            self.finishIdle()
        }
    }

    private func finishIdle() {
        runningAction = nil
        setPhase(.idle)
    }

    private func apply(_ state: SelectionState) {
        hasSelection = state.hasSelection
        selectedText = state.selectedText
        onSelectionChange?()
    }

    private func setPhase(_ newPhase: SelectionActionPhase) {
        phase = newPhase
        onSelectionChange?()
    }

    isolated deinit {
        observationTask?.cancel()
        actionTask?.cancel()
        failedResetTask?.cancel()
    }
}
