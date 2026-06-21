import AppKit
import Foundation
import OSLog

/// Backs the hidden Developer section: the version-number unlock gesture plus
/// the debug actions (reveal model folders, open Console, reset app data).
/// `isUnlocked` is persisted, so once revealed the section stays put until the
/// user hides it again.
@Observable @MainActor final class DeveloperSettingsViewModel {

    private(set) var isUnlocked: Bool

    @ObservationIgnored private var tapCount = 0
    @ObservationIgnored private let defaults: UserDefaults
    private static let tapsToUnlock = 7

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isUnlocked = defaults.bool(forKey: Preferences.Key.developerModeEnabled)
    }

    /// Counts taps on the version number; reveals the section on the 7th.
    func registerVersionTap() {
        guard !isUnlocked else { return }
        tapCount += 1
        Log.app.debug("Developer unlock tap \(self.tapCount, privacy: .public)/\(Self.tapsToUnlock, privacy: .public)")
        guard tapCount >= Self.tapsToUnlock else { return }
        isUnlocked = true
        defaults.set(true, forKey: Preferences.Key.developerModeEnabled)
    }

    func hideDeveloperTools() {
        tapCount = 0
        isUnlocked = false
        defaults.set(false, forKey: Preferences.Key.developerModeEnabled)
    }

    func openConsole() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"))
    }

    /// Reveals every model folder that exists on disk; falls back to Application
    /// Support when nothing is installed yet.
    func revealModelFolders() {
        let roots = ModelStorage.revealableModelRoots()
        if roots.isEmpty {
            let appSupport = FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support", isDirectory: true)
            NSWorkspace.shared.open(appSupport)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting(roots)
        }
    }

    /// Wipes Voicy's UserDefaults (usage counters, plan flag, onboarding state)
    /// and relaunches — handy for re-testing Free limits. Keeps the developer
    /// unlock so the section survives the reset. The Keychain license isn't
    /// touched: an active subscription re-validates on next launch.
    func resetAppData() {
        clearAppData()
        AppRelauncher.relaunch()
    }

    /// The data-clearing half of `resetAppData`, without the relaunch, so it's
    /// unit-testable. Keeps the developer-unlock flag.
    func clearAppData() {
        for key in Preferences.Key.all where key != Preferences.Key.developerModeEnabled {
            defaults.removeObject(forKey: key)
        }
    }
}
