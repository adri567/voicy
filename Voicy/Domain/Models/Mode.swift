import Foundation

/// The six Mode types Voicy can run on a transcription before pasting.
nonisolated enum ModeType: String, Codable, Sendable, CaseIterable {
    case raw, translate, developer, email, snippets, custom

    var label: String {
        switch self {
        case .raw:       return "Raw"
        case .translate: return "Translate"
        case .developer: return "Developer"
        case .email:     return "Email"
        case .snippets:  return "Snippets"
        case .custom:    return "Custom"
        }
    }

    var glyph: String {
        switch self {
        case .raw:       return "∅"
        case .translate: return "⇄"
        case .developer: return "{ }"
        case .email:     return "✉"
        case .snippets:  return "❖"
        case .custom:    return "✱"
        }
    }

    var subtitle: String {
        switch self {
        case .raw:       return "No post-processing"
        case .translate: return "Translation"
        case .developer: return "AI rewrite"
        case .email:     return "AI rewrite"
        case .snippets:  return "Text replacement"
        case .custom:    return "Custom prompt"
        }
    }

    var blurb: String {
        switch self {
        case .raw:
            return "Paste the transcription verbatim — no rewriting, no translation."
        case .translate:
            return "Translate between two languages, preserving register."
        case .developer:
            return "Rewrite as concise technical English — commits, comments, dev chat."
        case .email:
            return "Rewrite as a polite, well-structured email body."
        case .snippets:
            return "Spot your snippet phrases in the transcription and replace them with the saved text. Deterministic — no LLM involved."
        case .custom:
            return "Your own system prompt. Name it, give it an icon."
        }
    }
}

/// A single slot in the user's Mode-Reel.
///
/// Only the fields relevant to `type` are read by the recording pipeline; the
/// others are kept around so the user can switch types and back without losing
/// their configuration.
nonisolated struct Mode: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var type: ModeType
    var targetCode: String?  // translate only
    var name: String?        // custom only
    var emoji: String?       // custom only
    var prompt: String?      // custom only

    init(
        id: UUID = UUID(),
        type: ModeType,
        targetCode: String? = nil,
        name: String? = nil,
        emoji: String? = nil,
        prompt: String? = nil
    ) {
        self.id = id
        self.type = type
        self.targetCode = targetCode
        self.name = name
        self.emoji = emoji
        self.prompt = prompt
    }
}

extension Mode {
    /// Display title for the slot card / editor header.
    func title(source: AppLanguage) -> String {
        switch type {
        case .raw, .developer, .email, .snippets:
            return type.label
        case .translate:
            let target = LanguageCatalog.language(for: targetCode ?? "en")
            return "\(source.native) → \(target.native)"
        case .custom:
            let trimmed = name?.trimmingCharacters(in: .whitespaces) ?? ""
            return trimmed.isEmpty ? "Untitled" : trimmed
        }
    }

    /// Emoji to use as the slot's visual glyph when one is available. Falls
    /// back to nil for types that should render their `ModeType.glyph`
    /// character instead (Raw, Developer, Email, Snippets).
    var displayEmoji: String? {
        switch type {
        case .translate:
            return LanguageCatalog.language(for: targetCode ?? "en").flag
        case .custom:
            let trimmed = emoji?.trimmingCharacters(in: .whitespaces) ?? ""
            return trimmed.isEmpty ? "✱" : trimmed
        case .raw, .developer, .email, .snippets:
            return nil
        }
    }

    var subtitleText: String {
        type.subtitle
    }
}

enum DefaultReel {
    /// Initial set written on first launch when no stored reel exists.
    /// Mirrors the design's default of 4 slots — Raw, two Translates, Email.
    static func make(sourceCode: String) -> [Mode] {
        let firstTarget  = sourceCode == "en" ? "de" : "en"
        let secondTarget = sourceCode == "fr" ? "es" : "fr"
        return [
            Mode(type: .raw),
            Mode(type: .translate, targetCode: firstTarget),
            Mode(type: .translate, targetCode: secondTarget),
            Mode(type: .email),
        ]
    }
}
