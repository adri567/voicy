import Foundation

/// Which text-correction backend the currently-selected brain runs on. Mirrors
/// `TranscriptionEngine` for the LLM layer: a pure UserDefaults-derived choice
/// the DI container reads to resolve the right `TextCorrectionService`.
///
/// Apple's built-in on-device model is addressed by a sentinel registry key
/// (`apple_fm`) — it isn't a downloadable MLX repo, so any non-sentinel key (or
/// none) routes to MLX.
nonisolated enum BrainBackend {
    case mlx
    case appleFoundationModels

    /// Sentinel `registryKey` for Apple's Foundation Models system model. Not a
    /// real Hugging Face repo — it only signals the backend switch.
    static let appleRegistryKey = "apple_fm"

    /// Backend implied by the persisted brain selection.
    static var current: BrainBackend {
        resolve(registryKey: UserDefaults.standard.string(forKey: Preferences.Key.llmRegistryKey))
    }

    /// Pure mapping from a stored registry key to a backend. Anything that
    /// isn't the Apple sentinel (including `nil`/unset) is an MLX brain.
    static func resolve(registryKey: String?) -> BrainBackend {
        registryKey == appleRegistryKey ? .appleFoundationModels : .mlx
    }
}
