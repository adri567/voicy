import Foundation

nonisolated enum TranscribeLanguageCatalog {

    /// All manually-selectable languages. Used by both source (without auto)
    /// and output pickers.
    static let allManual: [TranscribeLanguage] = [
        .init(code: "de", flag: "🇩🇪", name: "German",     native: "Deutsch"),
        .init(code: "en", flag: "🇺🇸", name: "English",    native: "English"),
        .init(code: "es", flag: "🇪🇸", name: "Spanish",    native: "Español"),
        .init(code: "fr", flag: "🇫🇷", name: "French",     native: "Français"),
        .init(code: "it", flag: "🇮🇹", name: "Italian",    native: "Italiano"),
        .init(code: "pt", flag: "🇵🇹", name: "Portuguese", native: "Português"),
        .init(code: "nl", flag: "🇳🇱", name: "Dutch",      native: "Nederlands"),
        .init(code: "pl", flag: "🇵🇱", name: "Polish",     native: "Polski"),
        .init(code: "sv", flag: "🇸🇪", name: "Swedish",    native: "Svenska"),
        .init(code: "tr", flag: "🇹🇷", name: "Turkish",    native: "Türkçe"),
        .init(code: "ja", flag: "🇯🇵", name: "Japanese",   native: "日本語"),
    ]

    static let autoDetect = TranscribeLanguage(
        code: "auto", flag: "✸", name: "Auto-detect", native: "Auto-detect"
    )

    /// Source picker options when auto-detect is available (Whisper).
    static let sourcesWithAuto: [TranscribeLanguage] = [autoDetect] + allManual

    /// Lookup helper. Returns the first matching language; falls back to
    /// German rather than crashing on unknown codes.
    static func source(_ code: String) -> TranscribeLanguage {
        if code == autoDetect.code { return autoDetect }
        return allManual.first(where: { $0.code == code }) ?? allManual[0]
    }
}
