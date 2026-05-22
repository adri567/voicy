import Foundation
@testable import Voicy

/// Clears the `UserDefaults` keys `ModeCycleService` persists to, so each test
/// starts from the default reel instead of inheriting a previous test's state.
/// `ModeCycleService` reads `UserDefaults.standard` directly, so suites that
/// touch it run `.serialized` and call this in their setup.
func clearModeCycleDefaults() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: Preferences.Key.modesReel)
    defaults.removeObject(forKey: Preferences.Key.sourceLanguageCode)
}
