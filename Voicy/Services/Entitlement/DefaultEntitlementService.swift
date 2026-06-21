import Foundation

/// Reads the Pro flag from `UserDefaults`. Stateless beyond the defaults
/// reference, so `plan` always reflects the latest stored value (e.g. right
/// after a relaunch following license activation).
///
/// Today the flag is set by the hidden debug toggle in Settings; once Lemon
/// Squeezy lands, the license service writes it after validating a key — no
/// other code in the app needs to change.
final class DefaultEntitlementService: EntitlementService {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var plan: Plan {
        defaults.bool(forKey: Preferences.Key.isPro) ? .pro : .free
    }

    func setPro(_ isPro: Bool) {
        defaults.set(isPro, forKey: Preferences.Key.isPro)
    }
}
