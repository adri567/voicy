struct LLMModel: Identifiable {
    enum Location { case local, cloud }

    let id: String
    let registryKey: String?    // nil for cloud-only models
    /// Real product name — used for cloud models that keep their own branding.
    let name: String
    let family: String
    let description: String
    let size: String
    let context: String
    let speed: String
    let quality: Double
    let location: Location
    let highlight: String?

    /// Voicy branding for on-device models, resolved from the central catalog.
    private var credit: ModelCredit? { registryKey.flatMap { ModelCatalog.brains[$0] } }

    /// Name shown in the interface: Voicy name for local models, real name for cloud.
    var displayName: String { credit?.voicyName ?? name }

    /// Tier tag for local models; nil for cloud (which shows its family label).
    var tier: String? { credit?.tier }

    /// Apple's built-in on-device brain: ships with the OS, so it's never
    /// downloaded and can't be removed. Drives the no-install/no-trash UI.
    var isBuiltIn: Bool { registryKey == BrainBackend.appleRegistryKey }

    var latencyNumber: String {
        switch speed {
        case "Real-time": "300"
        case "Fast":      "500"
        case "Medium":    "800"
        case "Slow":      "1400"
        default:           "—"
        }
    }
}
