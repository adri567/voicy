/// Single source of truth for Voicy's model branding. Every surface (Engine
/// library, Brain library, Home, Transcribe, Onboarding, Settings colophon)
/// reads names, tiers and license credits from here so they never drift.
///
/// Cloud brains keep their real product names and are intentionally absent —
/// only on-device models get Voicy names.
nonisolated enum ModelCatalog {

    /// Keyed by WhisperKit model ID / Parakeet version (the engine `libraryID`).
    static let engines: [String: ModelCredit] = [
        "openai_whisper-tiny": ModelCredit(
            voicyName: "Murmur", tier: "Lite",
            underlyingModel: "OpenAI Whisper Tiny",
            copyright: "© OpenAI", license: .mit
        ),
        "openai_whisper-small": ModelCredit(
            voicyName: "Cadence", tier: "Standard",
            underlyingModel: "OpenAI Whisper Small",
            copyright: "© OpenAI", license: .mit
        ),
        "openai_whisper-large-v3_947MB": ModelCredit(
            voicyName: "Aria", tier: "Pro",
            underlyingModel: "OpenAI Whisper Large v3",
            copyright: "© OpenAI", license: .mit
        ),
        "v3": ModelCredit(
            voicyName: "Falcon", tier: "Rapid",
            underlyingModel: "NVIDIA Parakeet TDT 1.1B",
            copyright: "© NVIDIA", license: .ccBy4
        ),
    ]

    /// Keyed by MLX registry key (the brain `registryKey`).
    static let brains: [String: ModelCredit] = [
        "gemma4_e2b_it_4bit": ModelCredit(
            voicyName: "Quill", tier: "Lite",
            underlyingModel: "Google Gemma 4 E2B",
            copyright: "© Google", license: .apache2
        ),
        "gemma4_e4b_it_4bit": ModelCredit(
            voicyName: "Folio", tier: "Standard",
            underlyingModel: "Google Gemma 4 E4B",
            copyright: "© Google", license: .apache2
        ),
        "qwen2_5_7b": ModelCredit(
            voicyName: "Atlas", tier: "Pro",
            underlyingModel: "Alibaba Qwen 2.5 7B",
            copyright: "© Alibaba", license: .apache2
        ),
    ]

    /// Colophon order: smallest tier → largest.
    static let engineCredits: [ModelCredit] = [
        "openai_whisper-tiny",
        "openai_whisper-small",
        "openai_whisper-large-v3_947MB",
        "v3",
    ].compactMap { engines[$0] }

    static let brainCredits: [ModelCredit] = [
        "gemma4_e2b_it_4bit",
        "gemma4_e4b_it_4bit",
        "qwen2_5_7b",
    ].compactMap { brains[$0] }

    // MARK: - Display lookups

    /// Voicy name for an engine library ID, falling back to a neutral label.
    static func engineName(forLibraryID id: String) -> String {
        engines[id]?.voicyName ?? "Engine"
    }

    /// Voicy name for a brain registry key, falling back to a neutral label.
    static func brainName(forRegistryKey key: String) -> String {
        brains[key]?.voicyName ?? "Brain"
    }
}
