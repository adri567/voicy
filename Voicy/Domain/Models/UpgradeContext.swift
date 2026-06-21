import Foundation

/// Why the paywall was shown. Drives a context-specific headline/body so the
/// upgrade prompt speaks to the exact limit the user just hit, while sharing
/// one reusable `PaywallSheet`. `Identifiable` so it can drive a SwiftUI
/// `.sheet(item:)`.
nonisolated enum UpgradeContext: String, Identifiable, Sendable {
    case wordLimit
    case fileMinutes
    case modeSlots
    case customMode
    case brainModel
    case snippets

    var id: String { rawValue }

    /// Short, benefit-led headline.
    var title: String {
        switch self {
        case .wordLimit:   return "You've hit your weekly words"
        case .fileMinutes: return "Monthly transcription limit reached"
        case .modeSlots:   return "Want more mode slots?"
        case .customMode:  return "Custom modes are a Pro feature"
        case .brainModel:  return "Unlock every AI model"
        case .snippets:    return "Room for more snippets"
        }
    }

    /// One-sentence explanation of what Pro changes for this limit.
    var message: String {
        switch self {
        case .wordLimit:
            return "Free includes \(PlanLimits.freeWeeklyWords) dictated words a week. Upgrade to Pro for unlimited dictation."
        case .fileMinutes:
            return "Free includes \(PlanLimits.freeMonthlyFileMinutes) minutes of file transcription a month. Pro removes the cap."
        case .modeSlots:
            return "Free reels hold \(PlanLimits.freeModeSlots) slots. Pro lets you build up to \(PlanLimits.proModeSlots)."
        case .customMode:
            return "Write your own system prompt and craft a mode that sounds exactly like you — with Pro."
        case .brainModel:
            return "Free runs on the standard brain. Pro unlocks the larger, more capable models for sharper rewriting and translation."
        case .snippets:
            return "Free stores \(PlanLimits.freeSnippets) snippets. Pro makes them unlimited."
        }
    }
}
