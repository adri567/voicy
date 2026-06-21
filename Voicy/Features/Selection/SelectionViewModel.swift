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

    /// True while an action is actively running. The coordinator uses this to
    /// block the Fn hotkey so starting a recording can't interrupt a correction.
    var isWorking: Bool { phase == .working }

    /// Called after every selection- or phase change so the owner
    /// (AppCoordinator) can re-evaluate panel visibility. Keeps window
    /// orchestration out of the view model.
    @ObservationIgnored
    var onSelectionChange: (() -> Void)?

    /// Called when an action is blocked by the Free word limit so the owner
    /// (AppCoordinator) can surface the paywall. Falls back to a brief failure
    /// hint when unset.
    @ObservationIgnored
    var onUpgradeNeeded: (() -> Void)?

    @ObservationIgnored
    private let selectionService: any SelectionService
    @ObservationIgnored
    private let correctionService: any TextCorrectionService
    @ObservationIgnored
    private let pasteService: any PasteService
    @ObservationIgnored
    private let entitlement: any EntitlementService
    @ObservationIgnored
    private let usageTracking: any UsageTrackingService
    @ObservationIgnored
    private let telemetry: any TelemetryService
    /// Caps the LLM generation step. Model loading is timed separately so a cold
    /// 2GB+ brain can't trip this.
    @ObservationIgnored
    private let inferenceTimeout: Duration
    /// Generous cap on loading the brain into memory (only hit by a click that
    /// lands before the launch warm-up finishes).
    @ObservationIgnored
    private let modelLoadTimeout: Duration

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?
    @ObservationIgnored
    private var actionTask: Task<Void, Never>?
    @ObservationIgnored
    private var failedResetTask: Task<Void, Never>?

    /// Selection the user dismissed by starting a recording instead of choosing
    /// an action. Stays hidden until the selection actually changes.
    @ObservationIgnored
    private var dismissedSelection: String?

    /// How long the failed-hint stays up before returning to idle.
    private static let failedHintDuration: Duration = .seconds(1.5)

    /// Constructor injection (defaulting to the Factory registrations) keeps the
    /// view model decoupled from the shared container, so unit tests can pass
    /// mocks directly without racing other suites over global registration.
    init(
        selectionService: any SelectionService = Container.shared.selectionService(),
        correctionService: any TextCorrectionService = Container.shared.textCorrectionService(),
        pasteService: any PasteService = Container.shared.pasteService(),
        entitlement: any EntitlementService = Container.shared.entitlementService(),
        usageTracking: any UsageTrackingService = Container.shared.usageTrackingService(),
        telemetry: any TelemetryService = Container.shared.telemetryService(),
        inferenceTimeout: Duration = .seconds(30),
        modelLoadTimeout: Duration = .seconds(120)
    ) {
        self.selectionService = selectionService
        self.correctionService = correctionService
        self.pasteService = pasteService
        self.entitlement = entitlement
        self.usageTracking = usageTracking
        self.telemetry = telemetry
        self.inferenceTimeout = inferenceTimeout
        self.modelLoadTimeout = modelLoadTimeout
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

    /// Hides the pill for the currently selected text because the user chose to
    /// dictate (pressed Fn) rather than run an action on it. Stays hidden until
    /// a different selection appears.
    func dismissCurrentSelection() {
        guard hasSelection else { return }
        dismissedSelection = selectedText
        hasSelection = false
        onSelectionChange?()
    }

    /// Runs `action` on the live selection with the installed brain and writes
    /// the result back in place. No-ops if already working, nothing is selected,
    /// or no brain is installed (the latter shows a brief failure hint).
    func run(_ action: SelectionAction) {
        guard phase == .idle else { return }
        telemetry.breadcrumb("selection \(String(describing: action))", category: .selection)

        let original = selectionService.currentSelection().selectedText
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Proofread/rephrase draw from the same rolling word budget as live
        // dictation. A tapped-out Free user gets the paywall instead.
        if wordLimitReached {
            onUpgradeNeeded?()
            fail(action)
            return
        }

        guard correctionService.ensureModelAvailable() else {
            fail(action)
            return
        }

        runningAction = action
        setPhase(.working)
        let service = correctionService
        let inferenceTimeout = inferenceTimeout
        let loadTimeout = modelLoadTimeout
        actionTask = Task { [weak self] in
            do {
                // Load the brain *outside* the inference timeout — a cold 2GB+
                // model (or one still warming up from launch) can take longer
                // than the generation itself, and that wait must not be counted
                // as a failure. Sharing the in-flight launch warm-up makes this a
                // cheap await once it's resident.
                try await withTimeout(loadTimeout) { try await service.loadModel() }
                let corrected = try await withTimeout(inferenceTimeout) {
                    try await Self.apply(action, to: original, using: service)
                }
                guard let self, !Task.isCancelled else { return }
                self.applyCorrection(corrected, original: original)
            } catch is CancellationError {
                // Superseded/torn down — leave state as the canceller set it.
            } catch {
                Log.app.error("Selection \(String(describing: action), privacy: .public) failed: \(String(describing: error), privacy: .public)")
                self?.telemetry.capture(error, context: ["stage": "selection", "action": String(describing: action)])
                self?.fail(action)
            }
        }
    }

    // MARK: - Private

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
        // Book the written words against the rolling window (Free only).
        if entitlement.weeklyWordLimit != nil {
            usageTracking.recordWords(corrected.wordCount)
        }
        finishIdle()
    }

    /// True when a Free user has reached the rolling weekly word allowance.
    /// Pro (a `nil` limit) never trips this.
    private var wordLimitReached: Bool {
        guard let limit = entitlement.weeklyWordLimit else { return false }
        return usageTracking.wordsUsedLast7Days() >= limit
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
        selectedText = state.selectedText
        if state.hasSelection, state.selectedText == dismissedSelection {
            // Same selection the user dictated over — keep it hidden.
            hasSelection = false
        } else {
            dismissedSelection = nil
            hasSelection = state.hasSelection
        }
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
