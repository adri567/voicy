import Foundation

/// UI state for a single onboarding model/brain download. Onboarding only needs
/// the linear lifecycle (no "installed but not active" distinction the library
/// ViewModels carry), so this is deliberately simpler than
/// `EngineViewModel.Status`.
nonisolated enum DownloadUIState: Equatable {
    case idle
    case inProgress(DownloadPhase)
    case ready
    case failed(String)

    var isReady: Bool { self == .ready }

    var isInProgress: Bool {
        if case .inProgress = self { return true }
        return false
    }

    /// The active download phase, if any — drives the progress indicator.
    var phase: DownloadPhase? {
        if case .inProgress(let phase) = self { return phase }
        return nil
    }

    var errorText: String? {
        if case .failed(let message) = self { return message }
        return nil
    }

    /// Folds a new phase in, keeping progress monotonic. No-op unless currently
    /// `.inProgress` (so late callbacks can't revive a finished/failed state).
    func advanced(to next: DownloadPhase) -> DownloadUIState {
        guard case .inProgress(let current) = self else { return self }
        return .inProgress(current.advanced(to: next))
    }
}
