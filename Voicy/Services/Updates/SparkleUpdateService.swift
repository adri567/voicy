import Sparkle

/// Sparkle-backed `UpdateService`. Wraps `SPUStandardUpdaterController`, which
/// owns the updater plus the standard user-facing UI driver. Constructing it
/// with `startingUpdater: true` kicks off Sparkle's scheduled background checks
/// (interval/feed/public-key come from the `SU*` Info.plist keys).
///
/// MainActor-isolated by the module default — Sparkle's controller and its UI
/// must live on the main thread. Factory builds it via `MainActor.assumeIsolated`.
final class SparkleUpdateService: UpdateService {

    private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
