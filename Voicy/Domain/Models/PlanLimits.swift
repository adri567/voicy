import Foundation

/// Central policy for the Free/Pro split. Every Free-tier cap lives here so the
/// numbers never drift between the gates that enforce them and the UI that
/// communicates them. Pro lifts all of these (unlimited where applicable).
nonisolated enum PlanLimits {
    /// Mode-Reel: Raw (locked slot 0) + 2 freely chosen slots on Free.
    static let freeModeSlots = 3
    /// Absolute reel capacity (Pro). Also the hard array cap in ModeCycleService.
    static let proModeSlots = 6

    /// Stored snippets allowed on Free.
    static let freeSnippets = 2

    /// Rolling 7-day dictation word allowance on Free. Shared across live
    /// dictation and the selection-pill (proofread/rephrase). Kept deliberately
    /// tight because file transcription has its own separate monthly budget
    /// (`freeMonthlyFileMinutes`) — the two don't compete.
    static let freeWeeklyWords = 1500

    /// File-transcription minutes per calendar month on Free.
    static let freeMonthlyFileMinutes = 30

    /// The bundled MLX brain a Free user gets by default: Quill (Gemma 4 E2B).
    /// Matches the registry key in `ModelCatalog.brains`.
    static let freeBrainRegistryKey = "gemma4_e2b_it_4bit"

    /// Every brain a Free user may select without Pro. Apple's built-in
    /// on-device model is free (zero download, part of the OS); Quill remains
    /// the bundled MLX free brain. Pro unlocks all the heavier local brains.
    static let freeBrainRegistryKeys: Set<String> = [
        freeBrainRegistryKey,
        BrainBackend.appleRegistryKey,
    ]
}
