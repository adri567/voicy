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

    private(set) var statuses: [String: Status] = [:]
    private(set) var lastError: String?

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
}
