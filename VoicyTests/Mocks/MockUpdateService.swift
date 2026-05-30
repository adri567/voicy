@testable import Voicy

/// Records update-check calls so DI wiring can be verified without launching
/// Sparkle's real updater/UI. `@MainActor` to be `Sendable` despite mutable state.
@MainActor
final class MockUpdateService: UpdateService {
    nonisolated init() {}

    var canCheckForUpdates = true
    private(set) var checkCount = 0

    func checkForUpdates() { checkCount += 1 }
}
