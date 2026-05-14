import Foundation

nonisolated struct AppLanguage: Identifiable, Hashable, Sendable {
    let code: String
    let flag: String
    let name: String
    let native: String
    var id: String { code }
}

nonisolated enum LanguageCatalog {
    // 13 languages — mirrors design bundle voicy/project/components/LanguagesView.jsx
    static let all: [AppLanguage] = [
        .init(code: "de", flag: "🇩🇪", name: "German",     native: "Deutsch"),
        .init(code: "en", flag: "🇺🇸", name: "English",    native: "English"),
        .init(code: "es", flag: "🇪🇸", name: "Spanish",    native: "Español"),
        .init(code: "fr", flag: "🇫🇷", name: "French",     native: "Français"),
        .init(code: "it", flag: "🇮🇹", name: "Italian",    native: "Italiano"),
        .init(code: "pt", flag: "🇵🇹", name: "Portuguese", native: "Português"),
        .init(code: "nl", flag: "🇳🇱", name: "Dutch",      native: "Nederlands"),
        .init(code: "pl", flag: "🇵🇱", name: "Polish",     native: "Polski"),
        .init(code: "ru", flag: "🇷🇺", name: "Russian",    native: "Русский"),
        .init(code: "sv", flag: "🇸🇪", name: "Swedish",    native: "Svenska"),
        .init(code: "da", flag: "🇩🇰", name: "Danish",     native: "Dansk"),
        .init(code: "no", flag: "🇳🇴", name: "Norwegian",  native: "Norsk"),
        .init(code: "tr", flag: "🇹🇷", name: "Turkish",    native: "Türkçe"),
    ]

    static let samplePreviews: [String: String] = [
        "de": "Können wir das Meeting auf nächste Woche verschieben? Mir ist heute etwas dazwischen gekommen.",
        "en": "Could we push the meeting to next week? Something came up on my end today.",
        "es": "¿Podríamos posponer la reunión a la próxima semana? Hoy me ha surgido un imprevisto.",
        "fr": "Pourrions-nous reporter la réunion à la semaine prochaine ? Un imprévu m’est arrivé aujourd’hui.",
        "it": "Possiamo spostare la riunione alla prossima settimana? Oggi mi è capitato un imprevisto.",
        "pt": "Podemos adiar a reunião para a próxima semana? Surgiu algo do meu lado hoje.",
        "nl": "Kunnen we de meeting verplaatsen naar volgende week? Er kwam vandaag iets tussen.",
        "pl": "Czy moglibyśmy przełożyć spotkanie na przyszły tydzień? Coś mi dziś wypadło.",
        "ru": "Можем перенести встречу на следующую неделю? У меня сегодня кое-что появилось.",
        "sv": "Kan vi flytta mötet till nästa vecka? Det dök upp något hos mig idag.",
        "da": "Kan vi rykke mødet til næste uge? Der dukkede noget op for mig i dag.",
        "no": "Kan vi flytte møtet til neste uke? Det dukket opp noe hos meg i dag.",
        "tr": "Toplantıyı önümüzdeki haftaya alabilir miyiz? Bugün acil bir işim çıktı.",
    ]

    /// Short question samples used as a second few-shot example in the
    /// translation prompt — proves to weak instruction-tuned LLMs that
    /// questions are *translated*, not answered.
    static let questionPreviews: [String: String] = [
        "de": "Wie geht es dir heute?",
        "en": "How are you doing today?",
        "es": "¿Cómo estás hoy?",
        "fr": "Comment vas-tu aujourd’hui ?",
        "it": "Come stai oggi?",
        "pt": "Como estás hoje?",
        "nl": "Hoe gaat het vandaag?",
        "pl": "Jak się masz dzisiaj?",
        "ru": "Как у тебя дела сегодня?",
        "sv": "Hur mår du idag?",
        "da": "Hvordan har du det i dag?",
        "no": "Hvordan har du det i dag?",
        "tr": "Bugün nasılsın?",
    ]

    static func language(for code: String) -> AppLanguage {
        all.first(where: { $0.code == code }) ?? all[0]
    }
}
