import Foundation
import Observation

/// Tracks install/remove state for every real ASR model in the EngineView library.
/// Operates on library-level IDs (`openai_whisper-small`, `v3`, etc.) via the
/// static helpers on `DefaultTranscriptionService` / `ParakeetTranscriptionService`.
@MainActor
@Observable
final class EngineViewModel {

    enum Status: Equatable {
        case notInstalled
        case downloading(Double)
        case installed     // on disk, not currently active
        case active        // on disk and currently loaded
    }

    enum Family { case whisper, parakeet }

    private(set) var statuses: [String: Status] = [:]
    private(set) var lastError: String?

    func refresh(whisperIDs: [String], parakeetVersions: [String]) {
        let currentEngine = TranscriptionEngine.current
        let activeWhisper  = DefaultTranscriptionService.activeModelID
        let activeParakeet = ParakeetTranscriptionService.activeVersion

        for id in whisperIDs {
            statuses[id] = resolveStatus(
                installed: DefaultTranscriptionService.isInstalled(modelID: id),
                isCurrent: currentEngine == .whisper && id == activeWhisper
            )
        }
        for v in parakeetVersions {
            statuses[v] = resolveStatus(
                installed: ParakeetTranscriptionService.isInstalled(version: v),
                isCurrent: currentEngine == .parakeet && v == activeParakeet
            )
        }
    }

    func install(family: Family, id: String) async {
        statuses[id] = .downloading(0)
        lastError = nil
        do {
            switch family {
            case .whisper:
                try await DefaultTranscriptionService.install(modelID: id) { fraction in
                    Task { @MainActor in self.updateProgress(id: id, fraction: fraction) }
                }
            case .parakeet:
                try await ParakeetTranscriptionService.install(version: id) { fraction in
                    Task { @MainActor in self.updateProgress(id: id, fraction: fraction) }
                }
            }
            statuses[id] = resolveStatus(
                installed: true,
                isCurrent: isCurrentlyActive(family: family, id: id)
            )
        } catch {
            statuses[id] = .notInstalled
            lastError = error.localizedDescription
        }
    }

    /// Updates the progress only if the model is still in the downloading
    /// state. Prevents late progress callbacks from overwriting a final
    /// `.installed`/`.active` state set after `install` returned.
    private func updateProgress(id: String, fraction: Double) {
        guard case .downloading = statuses[id] else { return }
        statuses[id] = .downloading(fraction)
    }

    func remove(family: Family, id: String) async {
        lastError = nil
        do {
            switch family {
            case .whisper:  try DefaultTranscriptionService.remove(modelID: id)
            case .parakeet: try ParakeetTranscriptionService.remove(version: id)
            }
            statuses[id] = .notInstalled
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Switches the active model. Persists the choice and relaunches the app —
    /// the new singleton-scoped service will pick up the value on next launch.
    func setAsDefault(family: Family, id: String) {
        switch family {
        case .whisper:
            UserDefaults.standard.set(id, forKey: Preferences.Key.whisperModelID)
            TranscriptionEngine.current = .whisper
        case .parakeet:
            UserDefaults.standard.set(id, forKey: Preferences.Key.parakeetVersion)
            TranscriptionEngine.current = .parakeet
        }
        AppRelauncher.relaunch()
    }

    // MARK: - Derived

    func whisperIDs(from models: [EngineModel]) -> [String] {
        models.filter { $0.family == .whisper }.map(\.libraryID)
    }

    func parakeetVersions(from models: [EngineModel]) -> [String] {
        models.filter { $0.family == .parakeet }.map(\.libraryID)
    }

    func activeModel(in models: [EngineModel]) -> EngineModel {
        let activeID: String
        switch TranscriptionEngine.current {
        case .whisper:  activeID = DefaultTranscriptionService.activeModelID
        case .parakeet: activeID = ParakeetTranscriptionService.activeVersion
        }
        return models.first { $0.libraryID == activeID } ?? models[1]
    }

    /// Stable-sort by install status: active → installed → downloading → not-installed.
    /// Ties keep the original catalog order.
    func sortedModels(_ models: [EngineModel]) -> [EngineModel] {
        models.enumerated().sorted { lhs, rhs in
            let lp = statusPriority(statuses[lhs.element.libraryID] ?? .notInstalled)
            let rp = statusPriority(statuses[rhs.element.libraryID] ?? .notInstalled)
            if lp != rp { return lp < rp }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func statusPriority(_ status: Status) -> Int {
        switch status {
        case .active:       return 0
        case .installed:    return 1
        case .downloading:  return 2
        case .notInstalled: return 3
        }
    }

    // MARK: - Helpers

    private func resolveStatus(installed: Bool, isCurrent: Bool) -> Status {
        if !installed { return .notInstalled }
        return isCurrent ? .active : .installed
    }

    private func isCurrentlyActive(family: Family, id: String) -> Bool {
        let current = TranscriptionEngine.current
        switch family {
        case .whisper:  return current == .whisper  && id == DefaultTranscriptionService.activeModelID
        case .parakeet: return current == .parakeet && id == ParakeetTranscriptionService.activeVersion
        }
    }
}
