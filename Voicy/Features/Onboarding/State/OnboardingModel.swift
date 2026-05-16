// Voice model catalogue — mirrors the design bundle MODELS list.
struct OnboardingModel: Identifiable, Hashable {
    let id: String
    let family: String
    let label: String
    let displaySize: String
    let wer: String
    let speed: String
    let body: String
    let recommended: Bool
    let engine: TranscriptionEngine
    /// Real identifier used by the engine: WhisperKit model name or Parakeet version.
    let realID: String
}
