import OSLog

/// Central `os.Logger` registry. Categories group log lines by subsystem area
/// so Console.app can filter them. Replaces ad-hoc `print` calls. Dynamic
/// values are redacted by default; only values explicitly marked
/// `privacy: .public` show up in release builds — transcript text stays
/// private.
enum Log {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.voicy.Voicy"

    nonisolated static let app = Logger(subsystem: subsystem, category: "app")
    nonisolated static let recording = Logger(subsystem: subsystem, category: "recording")
    nonisolated static let transcription = Logger(subsystem: subsystem, category: "transcription")
    nonisolated static let llm = Logger(subsystem: subsystem, category: "llm")
    nonisolated static let audio = Logger(subsystem: subsystem, category: "audio")
    nonisolated static let diarization = Logger(subsystem: subsystem, category: "diarization")
    nonisolated static let history = Logger(subsystem: subsystem, category: "history")
    nonisolated static let settings = Logger(subsystem: subsystem, category: "settings")
}
