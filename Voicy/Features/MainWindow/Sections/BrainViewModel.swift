import FactoryKit
import Foundation
import Observation

/// State tracking for the active LLM (Gemma 4 E2B) in BrainView.
///
/// V1: only the active LLM model has real install/remove. Mock models in the
/// library stay no-op.
@MainActor
@Observable
final class BrainViewModel {

    enum Status: Equatable {
        case notInstalled
        case downloading(Double)
        case active           // installed + loaded in RAM
    }

    @ObservationIgnored
    @Injected(\.textCorrectionService) private var service

    private(set) var status: Status = .notInstalled
    private(set) var lastError: String?

    func refresh() {
        status = service.isModelInstalled() ? .active : .notInstalled
    }

    func install() async {
        status = .downloading(0)
        lastError = nil
        do {
            try await service.installModel { fraction in
                Task { @MainActor in
                    self.status = .downloading(fraction)
                }
            }
            status = .active
        } catch {
            status = service.isModelInstalled() ? .active : .notInstalled
            lastError = error.localizedDescription
        }
    }

    func remove() async {
        lastError = nil
        do {
            try await service.removeModel()
            status = .notInstalled
        } catch {
            lastError = error.localizedDescription
        }
    }
}
