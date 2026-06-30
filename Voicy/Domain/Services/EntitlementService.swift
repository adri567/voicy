import Foundation

/// Single source of truth for the user's plan and every Free-tier limit. Gates
/// across the app read their allowances from here so the Free/Pro split stays
/// consistent. Implementations only need to supply `plan` — all the derived
/// limits come from `PlanLimits` via the extension below, so mocks just set a
/// plan and the whole policy follows.
///
/// The Pro state is owned by the implementation: a local flag today, a Lemon
/// Squeezy license check once that lands. Plan changes take effect on relaunch
/// (same pattern as switching the active engine/brain), so this needs no
/// observation.
protocol EntitlementService: Sendable {
    var plan: Plan { get }

    /// Sets the Pro entitlement. Today the debug toggle and the paywall's
    /// "Upgrade" action call this directly; once Lemon Squeezy lands, the
    /// license check becomes the sole caller after validating a key. Plan
    /// changes take effect on the next relaunch.
    func setPro(_ isPro: Bool)
}

extension EntitlementService {
    var isPro: Bool { plan == .pro }

    /// Free uses the bundled standard brain (Quill) or Apple's built-in
    /// on-device model; Pro unlocks any brain.
    func canUseBrain(registryKey: String) -> Bool {
        isPro || PlanLimits.freeBrainRegistryKeys.contains(registryKey)
    }

    /// Custom-prompt mode is Pro-only — the strongest upgrade hook.
    var allowsCustomMode: Bool { isPro }

    /// Max Mode-Reel slots for the current plan.
    var maxModeSlots: Int {
        isPro ? PlanLimits.proModeSlots : PlanLimits.freeModeSlots
    }

    /// Max stored snippets; `nil` = unlimited.
    var maxSnippets: Int? {
        isPro ? nil : PlanLimits.freeSnippets
    }

    /// Rolling 7-day dictation word allowance; `nil` = unlimited.
    var weeklyWordLimit: Int? {
        isPro ? nil : PlanLimits.freeWeeklyWords
    }

    /// Monthly file-transcription minute allowance; `nil` = unlimited.
    var monthlyFileMinuteLimit: Int? {
        isPro ? nil : PlanLimits.freeMonthlyFileMinutes
    }
}
