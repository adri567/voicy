import Foundation
import NaturalLanguage

/// Wraps Apple's `NLLanguageRecognizer` for post-transcription language
/// detection. Used so the UI can show what the engine actually transcribed
/// (e.g. English) when it diverges from the user's manual Source-pick (e.g.
/// German), which is especially relevant for Parakeet where the Source hint
/// only affects Unicode-script filtering, not language identification.
nonisolated enum LanguageDetector {

    /// Returns ISO-639-1 language code (e.g. "de", "en", "fr") or nil if the
    /// recognizer isn't confident enough. `minimumConfidence` defaults to 0.6
    /// to avoid swapping the label on noisy / very short outputs.
    static func detect(from text: String, minimumConfidence: Double = 0.6) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 12 else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        guard let best = hypotheses.max(by: { $0.value < $1.value }),
              best.value >= minimumConfidence else { return nil }
        return best.key.rawValue
    }
}
