import Foundation

/// The single sentence rendered through every slot in the "One sentence,
/// every mode" panel. Designed to make the difference between modes legible
/// at a glance (statement + scheduling request).
enum ModesSample {
    static let inputCode = "de"
    static let input = "Können wir das Meeting auf nächste Woche verschieben? Mir ist heute etwas dazwischen gekommen."
    static let developer = "Pushing the sync to next week — got pulled into something today."
    static let email = """
    Hi team,

    Would it be possible to push our meeting to next week? Something unexpected came up on my end today, and I'd like to give the discussion the attention it deserves.

    Thanks,
    """
    static let customFallback = "hey — can we move the mtg to next wk? smth came up today 🙏"
    static let snippetsSample = "Können wir das Meeting auf nächste Woche verschieben? Mir ist heute etwas dazwischen gekommen. Beste Grüße, Adrian"

    static func translate(target: String) -> String {
        switch target {
        case "en": return "Could we push the meeting to next week? Something came up on my end today."
        case "fr": return "Pourrions-nous reporter la réunion à la semaine prochaine ? Un imprévu m'est arrivé aujourd'hui."
        case "es": return "¿Podríamos posponer la reunión a la próxima semana? Hoy me ha surgido un imprevisto."
        case "it": return "Possiamo spostare la riunione alla prossima settimana? Oggi mi è capitato un imprevisto."
        case "nl": return "Kunnen we de meeting verplaatsen naar volgende week? Er kwam vandaag iets tussen."
        case "pt": return "Podemos adiar a reunião para a próxima semana? Surgiu algo do meu lado hoje."
        case "pl": return "Czy moglibyśmy przełożyć spotkanie na przyszły tydzień? Coś mi dziś wypadło."
        case "sv": return "Kan vi flytta mötet till nästa vecka? Det dök upp något hos mig idag."
        case "ru": return "Можем перенести встречу на следующую неделю? У меня сегодня кое-что появилось."
        case "da": return "Kan vi rykke mødet til næste uge? Der dukkede noget op for mig i dag."
        case "ja": return "来週に打ち合わせをずらせますか？今日はこちらで急な用事ができてしまって。"
        case "de": return ModesSample.input
        default: return "[Sample translation to \(target.uppercased()) appears here when this mode runs.]"
        }
    }

    static func output(for mode: Mode) -> String {
        switch mode.type {
        case .raw:       return input
        case .translate: return translate(target: mode.targetCode ?? "en")
        case .developer: return developer
        case .email:     return email
        case .snippets:  return snippetsSample
        case .custom:    return customFallback
        }
    }
}
