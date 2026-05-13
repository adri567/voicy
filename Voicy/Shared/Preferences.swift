import Foundation

nonisolated enum Preferences {
    enum Key {
        static let showTranscript = "dev.showTranscript"
        static let transcriptionEngine = "dev.transcriptionEngine"
        static let firstLaunchCompleted = "dev.firstLaunchCompleted"
        static let languageSourceCode = "dev.languageSourceCode"
        static let languageTargetCodes = "dev.languageTargetCodes"
    }
}
