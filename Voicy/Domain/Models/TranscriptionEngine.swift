import Foundation

enum TranscriptionEngine: String, CaseIterable {
    case whisper = "whisper"
    case parakeet = "parakeet"

    /// Neutral, vendor-free label. A history entry only records the engine
    /// family, not the specific model, so this can't resolve to a single Voicy
    /// name — it stays generic on purpose.
    var displayName: String {
        switch self {
        case .whisper:  "On-device · multilingual"
        case .parakeet: "On-device · fast"
        }
    }

    nonisolated static var current: TranscriptionEngine {
        get {
            let raw = UserDefaults.standard.string(forKey: Preferences.Key.transcriptionEngine) ?? ""
            return TranscriptionEngine(rawValue: raw) ?? .whisper
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Preferences.Key.transcriptionEngine)
        }
    }
}
