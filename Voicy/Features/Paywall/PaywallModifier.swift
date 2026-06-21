import AppKit
import FactoryKit
import SwiftUI

/// Presents the shared `PaywallSheet` from any view via a bound
/// `UpgradeContext?`. Centralises the upgrade action so each gate only has to
/// set the binding — it doesn't repeat the purchase wiring.
///
/// "Upgrade" opens the Lemon Squeezy checkout in the browser; the user then
/// activates the emailed license key in Settings → Voicy Pro. The sheet never
/// grants Pro itself.
private struct PaywallModifier: ViewModifier {
    @Binding var context: UpgradeContext?

    @Injected(\.licenseService) private var license

    func body(content: Content) -> some View {
        content.sheet(item: $context) { ctx in
            PaywallSheet(context: ctx) {
                NSWorkspace.shared.open(license.checkoutURL)
            }
        }
    }
}

extension View {
    /// Shows the paywall whenever `context` is non-nil. Set the binding from a
    /// gate to surface the upgrade prompt for that specific limit.
    func paywall(_ context: Binding<UpgradeContext?>) -> some View {
        modifier(PaywallModifier(context: context))
    }
}
