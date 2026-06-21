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

        // Entitlement. `isPro` is the Pro-tier flag — set today by the hidden
        // Settings debug toggle, later by the Lemon Squeezy license check.
        static let isPro = "entitlement.isPro"
        // Usage counters: [dayKey: words] and [monthKey: minutes] dictionaries.
        static let usageWordBuckets = "usage.wordBuckets"
        static let usageFileMinuteBuckets = "usage.fileMinuteBuckets"
        // License. Unix timestamp of the last successful Lemon Squeezy
        // validation — the anchor for the offline grace window. The key and
        // instance id themselves live in the Keychain, not here.
        static let licenseLastValidated = "license.lastValidated"

        // Developer tools. Persisted unlock flag for the hidden Developer
        // section (revealed by tapping the version number).
        static let developerModeEnabled = "dev.developerModeEnabled"

        // Telemetry opt-out. Absent means crash reporting is on (the default);
        // the Settings "Diagnostics" toggle writes this. Stored as a positive
        // "enabled" flag so the toggle binds to it directly.
        static let telemetryEnabled = "telemetry.enabled"

        /// Every Voicy-owned key, for the Developer "reset app data" action.
        static let all: [String] = [
            showTranscript, transcriptionEngine, firstLaunchCompleted,
            sourceLanguageCode, modesReel, whisperModelID, parakeetVersion,
            llmRegistryKey, onboardingCompleted, onboardingClickSounds,
            onboardingOpenAtLogin, selectedAudioDeviceUID, isPro,
            usageWordBuckets, usageFileMinuteBuckets, licenseLastValidated,
            developerModeEnabled, telemetryEnabled
        ]
    }
}
