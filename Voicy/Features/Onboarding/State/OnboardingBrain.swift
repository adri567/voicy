struct OnboardingBrain: Identifiable, Hashable {
    let id: String
    let name: String
    let variant: String
    let family: String
    let size: String
    let context: String
    let speed: String
    let quality: Int
    let body: String
    let recommended: Bool
    /// MLX registry key understood by `MLXTextCorrectionService.install(...)`.
    /// Must be one of `MLXTextCorrectionService.supportedRegistryKeys`.
    let registryKey: String
}
