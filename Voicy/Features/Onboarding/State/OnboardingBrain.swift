struct OnboardingBrain: Identifiable, Hashable {
    let id: String
    let size: String
    let context: String
    let speed: String
    let quality: Int
    let body: String
    let recommended: Bool
    /// MLX registry key understood by `MLXTextCorrectionService.install(...)`.
    /// For downloadable brains this is one of
    /// `MLXTextCorrectionService.supportedRegistryKeys`; the built-in brain
    /// carries the `BrainBackend.appleRegistryKey` sentinel instead.
    let registryKey: String
    /// Apple's built-in Foundation Models brain: nothing to download and gated
    /// on device availability. Selecting it just switches the backend.
    var isBuiltIn: Bool = false

    /// Voicy branding, resolved from the central catalog. The built-in brain
    /// keeps Apple's own name rather than a Voicy alias.
    private var credit: ModelCredit? { ModelCatalog.brains[registryKey] }
    var name: String { isBuiltIn ? "Apple Intelligence" : (credit?.voicyName ?? "Brain") }
    var tier: String { isBuiltIn ? "Built-in" : (credit?.tier ?? "") }
}
