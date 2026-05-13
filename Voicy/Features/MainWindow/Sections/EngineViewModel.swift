import FactoryKit
import Foundation
import Observation

/// State tracking for the **currently active** ASR engine in the EngineView UI.
///
/// V1: only the active engine (whatever `TranscriptionEngine.current` resolves to)
/// gets install/remove controls. Non-active engines remain static "Set active"
/// rows — switching to them triggers an app relaunch via the existing flow.
@MainActor
@Observable
final class EngineViewModel {

    enum Status: Equatable {
        case notInstalled
        case downloading(Double)
        case active           // installed + loaded in RAM
    }

    @ObservationIgnored
    @Injected(\.transcriptionService) private var service

    private(set) var status: Status = .notInstalled
    private(set) var lastError: String?

    var currentEngine: TranscriptionEngine { .current }

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
