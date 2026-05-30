/// Maps a Voicy-branded model name to the open-source model that actually runs
/// underneath, with its copyright and license. The colophon's source of truth;
/// `ModelCatalog` exposes it keyed by the engine library ID / brain registry key.
nonisolated struct ModelCredit: Identifiable {
    /// The name shown in the interface, e.g. "Murmur".
    let voicyName: String
    /// Size/quality tier tag, e.g. "Lite", "Standard", "Pro", "Rapid".
    let tier: String
    /// The real model behind the name, e.g. "OpenAI Whisper Tiny".
    let underlyingModel: String
    /// Rights holder, e.g. "© OpenAI".
    let copyright: String
    let license: ModelLicense

    var id: String { voicyName }
}
