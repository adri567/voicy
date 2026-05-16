import SwiftUI

/// Small "Demo" badge used by all Settings rows that are not yet wired up to
/// real persistence — disambiguates mock controls from live ones at a glance.
struct SettingsMockBadge: View {
    var body: some View {
        Text("Demo")
            .font(DS.Font.mono(8))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(DS.Palette.ink3)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}
