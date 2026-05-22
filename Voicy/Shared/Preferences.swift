import Foundation

nonisolated enum Preferences {
    enum Key {
        static let showTranscript = "dev.showTranscript"
        static let transcriptionEngine = "dev.transcriptionEngine"
        static let firstLaunchCompleted = "dev.firstLaunchCompleted"
        static let sourceLanguageCode = "dev.sourceLanguageCode"
        static let modesReel = "dev.modesReel"
        // Active model identifiers per service family. Switched via "Set as default"
        // in EngineView/BrainView, followed by an app relaunch.
        static let whisperModelID  = "dev.whisperModelID"   // e.g. "openai_whisper-small"
        static let parakeetVersion = "dev.parakeetVersion"  // "v3" or "tdtCtc110m"
        static let llmRegistryKey  = "dev.llmRegistryKey"   // e.g. "gemma4_e2b_it_4bit"

        // Onboarding
        static let onboardingCompleted = "onboarding.completed"
        static let onboardingClickSounds = "onboarding.clickSounds"
        static let onboardingOpenAtLogin = "onboarding.openAtLogin"

        // Audio input. Stores the CoreAudio device UID (stable across replug);
        // empty/missing means "follow system default".
        static let selectedAudioDeviceUID = "audio.selectedDeviceUID"
    }
}
