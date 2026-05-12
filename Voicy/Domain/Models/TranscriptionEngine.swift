import Foundation

enum TranscriptionEngine: String, CaseIterable {
    case whisper = "whisper"
    case parakeet = "parakeet"

    var displayName: String {
        switch self {
        case .whisper:  "WhisperKit (Standard)"
        case .parakeet: "Parakeet TDT v3"
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
