// Voice model catalogue — names + tiers resolved from the central ModelCatalog.
struct OnboardingModel: Identifiable, Hashable {
    let id: String
    let displaySize: String
    let wer: String
    let speed: String
    let body: String
    let recommended: Bool
    let engine: TranscriptionEngine
    /// Real identifier used by the engine: WhisperKit model name or Parakeet version.
    let realID: String

    /// Voicy branding, resolved from the central catalog.
    private var credit: ModelCredit? { ModelCatalog.engines[realID] }
    var name: String { credit?.voicyName ?? "Engine" }
    var tier: String { credit?.tier ?? "" }
}
