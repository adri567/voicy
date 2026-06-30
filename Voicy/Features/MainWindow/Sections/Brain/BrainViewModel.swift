import FactoryKit
import Foundation
import Observation

/// Tracks install/remove state for every real local LLM in the BrainView library.
/// Operates on LLMRegistry keys (`gemma4_e2b_it_4bit`, `qwen2_5_7b`, etc.) via
/// the static helpers on `MLXTextCorrectionService`.
@MainActor
@Observable
final class BrainViewModel {

    @ObservationIgnored
    @Injected(\.entitlementService) private var entitlement

    @ObservationIgnored
    @Injected(\.telemetryService) private var telemetry

    /// Whether the given local model may be installed/used under the plan. Free
    /// is limited to the standard brain; Pro unlocks all. Cloud models aren't
    /// gated here (they're Coming Soon regardless).
    func canUse(_ model: LLMModel) -> Bool {
        guard let key = model.registryKey else { return true }
        return entitlement.canUseBrain(registryKey: key)
    }

    enum Status: Equatable {
        case notInstalled
        case downloading(DownloadPhase)
        case installed     // on disk, not currently active
        case active        // on disk and currently loaded
        /// Built-in brain (Apple Foundation Models) that exists but can't be
        /// used right now — Apple Intelligence off, unsupported device, etc.
        /// `reason` is a short user-facing explanation.
        case unavailable(reason: String)
    }

    /// Internal-settable (not `private(set)`) so unit tests can drive the
    /// filter + sort logic directly. Views only ever read it.
    var statuses: [String: Status] = [:]
    private(set) var lastError: String?

    /// Active filter chip — bound to the BrainFilterChip row.
    var filter: LLMFilter = .all

    func refresh(registryKeys: [String]) {
        let backend = BrainBackend.current
        let mlxActive = MLXTextCorrectionService.activeRegistryKey
        for key in registryKeys {
            if key == BrainBackend.appleRegistryKey {
                statuses[key] = appleStatus(backend: backend)
            } else {
                let installed = MLXTextCorrectionService.isInstalled(registryKey: key)
                if !installed {
                    statuses[key] = .notInstalled
                } else if backend == .mlx, key == mlxActive {
                    statuses[key] = .active
                } else {
                    // Installed, but not the active brain — either a non-active
                    // MLX model or any MLX model while Apple's brain is active.
                    statuses[key] = .installed
                }
            }
        }
    }

    /// Status for Apple's built-in brain: it's never downloaded, so it's
    /// `.active` when selected, `.installed` when available-but-not-selected,
    /// and `.unavailable` when Apple Intelligence can't serve it.
    private func appleStatus(backend: BrainBackend) -> Status {
        switch FoundationModelsTextCorrectionService.availability() {
        case .available:
            return backend == .appleFoundationModels ? .active : .installed
        case .unavailable(let reason):
            return .unavailable(reason: reason)
        }
    }

    func install(registryKey: String) async {
        // The built-in Apple brain has nothing to download.
        guard registryKey != BrainBackend.appleRegistryKey else { return }
        statuses[registryKey] = .downloading(.preparing)
        lastError = nil
        telemetry.breadcrumb("brain install \(registryKey)", category: .brain)
        do {
            try await MLXTextCorrectionService.install(registryKey: registryKey) { phase in
                Task { @MainActor in self.updateProgress(key: registryKey, phase: phase) }
            }
            let isActive = BrainBackend.current == .mlx && registryKey == MLXTextCorrectionService.activeRegistryKey
            statuses[registryKey] = isActive ? .active : .installed
        } catch {
            statuses[registryKey] = .notInstalled
            lastError = error.localizedDescription
            telemetry.capture(error, context: ["stage": "brain.install", "model": registryKey])
        }
    }

    /// Updates the progress only if the model is still in the downloading
    /// state. Prevents late progress callbacks from overwriting a final
    /// `.installed`/`.active` state set after `install` returned, and keeps the
    /// phase monotonic against out-of-order library callbacks.
    private func updateProgress(key: String, phase: DownloadPhase) {
        guard case .downloading(let current) = statuses[key] else { return }
        statuses[key] = .downloading(current.advanced(to: phase))
    }

    func remove(registryKey: String) async {
        // The built-in Apple brain can't be removed — it ships with the OS.
        guard registryKey != BrainBackend.appleRegistryKey else { return }
        lastError = nil
        telemetry.breadcrumb("brain remove \(registryKey)", category: .brain)
        do {
            try MLXTextCorrectionService.remove(registryKey: registryKey)
            statuses[registryKey] = .notInstalled
        } catch {
            lastError = error.localizedDescription
            telemetry.capture(error, context: ["stage": "brain.remove", "model": registryKey])
        }
    }

    /// Switches the active LLM. Persists the choice and relaunches the app.
    func setAsDefault(registryKey: String) {
        UserDefaults.standard.set(registryKey, forKey: Preferences.Key.llmRegistryKey)
        AppRelauncher.relaunch()
    }

    // MARK: - Derived (filtered + sorted view of the library catalog)

    func status(of model: LLMModel) -> Status? {
        guard let key = model.registryKey else { return nil }
        return statuses[key]
    }

    func activeModel(in models: [LLMModel]) -> LLMModel {
        let active = activeBrainKey
        return models.first { $0.registryKey == active } ?? models[0]
    }

    /// Registry key of the brain currently driving correction — Apple's sentinel
    /// key when the Foundation Models backend is active, otherwise the resolved
    /// MLX key. The MLX active key falls back to a default and can't represent
    /// "Apple is selected", so the backend has to be consulted first.
    private var activeBrainKey: String {
        switch BrainBackend.current {
        case .appleFoundationModels: return BrainBackend.appleRegistryKey
        case .mlx:                   return MLXTextCorrectionService.activeRegistryKey
        }
    }

    func localRegistryKeys(from models: [LLMModel]) -> [String] {
        models.compactMap { $0.location == .local ? $0.registryKey : nil }
    }

    /// Filter + stable-sort by status priority: active → installed → downloading → not-installed, cloud last.
    /// Ties keep the original catalog order so the recommended/default flags stay in their author-intended slots.
    func visibleModels(_ models: [LLMModel]) -> [LLMModel] {
        let filtered = models.filter { filter.matches($0, status: status(of: $0)) }
        return filtered.enumerated().sorted { lhs, rhs in
            let lp = sortPriority(model: lhs.element)
            let rp = sortPriority(model: rhs.element)
            if lp != rp { return lp < rp }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func sortPriority(model: LLMModel) -> Int {
        if model.location == .cloud { return 4 }
        switch status(of: model) {
        case .active:       return 0
        case .installed:    return 1
        case .downloading:  return 2
        case .notInstalled, .none: return 3
        case .unavailable:  return 3
        }
    }
}
