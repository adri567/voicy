import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("DeveloperSettingsViewModel")
struct DeveloperSettingsViewModelTests {

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "dev.test.\(UUID().uuidString)")!
    }

    @Test("Seven taps on the version unlock the section and persist the flag")
    func unlockAfterSevenTaps() {
        let defaults = makeDefaults()
        let vm = DeveloperSettingsViewModel(defaults: defaults)

        for _ in 0..<6 { vm.registerVersionTap() }
        #expect(vm.isUnlocked == false)

        vm.registerVersionTap() // 7th
        #expect(vm.isUnlocked)
        #expect(defaults.bool(forKey: Preferences.Key.developerModeEnabled))
    }

    @Test("A persisted flag unlocks the section on init")
    func unlockedFromDefaults() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: Preferences.Key.developerModeEnabled)
        #expect(DeveloperSettingsViewModel(defaults: defaults).isUnlocked)
    }

    @Test("Hiding clears the flag")
    func hide() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: Preferences.Key.developerModeEnabled)
        let vm = DeveloperSettingsViewModel(defaults: defaults)

        vm.hideDeveloperTools()

        #expect(vm.isUnlocked == false)
        #expect(defaults.bool(forKey: Preferences.Key.developerModeEnabled) == false)
    }

    @Test("clearAppData wipes Voicy keys but keeps the developer unlock")
    func clearKeepsUnlock() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: Preferences.Key.developerModeEnabled)
        defaults.set(true, forKey: Preferences.Key.isPro)
        defaults.set(["2026-05-31": 500], forKey: Preferences.Key.usageWordBuckets)
        let vm = DeveloperSettingsViewModel(defaults: defaults)

        vm.clearAppData()

        #expect(defaults.object(forKey: Preferences.Key.isPro) == nil)
        #expect(defaults.object(forKey: Preferences.Key.usageWordBuckets) == nil)
        // Developer unlock survives so the section doesn't vanish on reset.
        #expect(defaults.bool(forKey: Preferences.Key.developerModeEnabled))
    }
}
