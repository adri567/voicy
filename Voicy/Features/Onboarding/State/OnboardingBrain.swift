struct OnboardingBrain: Identifiable, Hashable {
    let id: String
    let size: String
    let context: String
    let speed: String
    let quality: Int
    let body: String
    let recommended: Bool
    /// MLX registry key understood by `MLXTextCorrectionService.install(...)`.
    /// Must be one of `MLXTextCorrectionService.supportedRegistryKeys`.
    let registryKey: String

    /// Voicy branding, resolved from the central catalog.
    private var credit: ModelCredit? { ModelCatalog.brains[registryKey] }
    var name: String { credit?.voicyName ?? "Brain" }
    var tier: String { credit?.tier ?? "" }
}
