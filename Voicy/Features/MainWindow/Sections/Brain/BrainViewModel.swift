import Foundation
import Observation

/// Tracks install/remove state for every real local LLM in the BrainView library.
/// Operates on LLMRegistry keys (`gemma4_e2b_it_4bit`, `qwen2_5_7b`, etc.) via
/// the static helpers on `MLXTextCorrectionService`.
@MainActor
@Observable
final class BrainViewModel {

    enum Status: Equatable {
        case notInstalled
        case downloading(Double)
        case installed     // on disk, not currently active
        case active        // on disk and currently loaded
    }

    /// Internal-settable (not `private(set)`) so unit tests can drive the
    /// filter + sort logic directly. Views only ever read it.
    var statuses: [String: Status] = [:]
    private(set) var lastError: String?

    /// Active filter chip — bound to the BrainFilterChip row.
    var filter: LLMFilter = .all

    func refresh(registryKeys: [String]) {
        let active = MLXTextCorrectionService.activeRegistryKey
        for key in registryKeys {
            let installed = MLXTextCorrectionService.isInstalled(registryKey: key)
            if !installed {
                statuses[key] = .notInstalled
            } else if key == active {
                statuses[key] = .active
            } else {
                statuses[key] = .installed
            }
        }
    }

    func install(registryKey: String) async {
        statuses[registryKey] = .downloading(0)
        lastError = nil
        do {
            try await MLXTextCorrectionService.install(registryKey: registryKey) { fraction in
                Task { @MainActor in self.updateProgress(key: registryKey, fraction: fraction) }
            }
            let isActive = registryKey == MLXTextCorrectionService.activeRegistryKey
            statuses[registryKey] = isActive ? .active : .installed
        } catch {
            statuses[registryKey] = .notInstalled
            lastError = error.localizedDescription
        }
    }

    /// Updates the progress only if the model is still in the downloading
    /// state. Prevents late progress callbacks from overwriting a final
    /// `.installed`/`.active` state set after `install` returned.
    private func updateProgress(key: String, fraction: Double) {
        guard case .downloading = statuses[key] else { return }
        statuses[key] = .downloading(fraction)
    }

    func remove(registryKey: String) async {
        lastError = nil
        do {
            try MLXTextCorrectionService.remove(registryKey: registryKey)
            statuses[registryKey] = .notInstalled
        } catch {
            lastError = error.localizedDescription
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
        let active = MLXTextCorrectionService.activeRegistryKey
        return models.first { $0.registryKey == active } ?? models[0]
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
        }
    }
}
