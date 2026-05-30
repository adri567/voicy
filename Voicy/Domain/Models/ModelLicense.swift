/// Open-source license a bundled model ships under. Surfaced in the Settings
/// colophon so the underlying weights are correctly attributed.
nonisolated enum ModelLicense: String, CaseIterable, Identifiable {
    case mit
    case apache2
    case ccBy4

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mit:     "MIT"
        case .apache2: "Apache 2.0"
        case .ccBy4:   "CC-BY-4.0"
        }
    }

    /// One-line explanation in plain language for the colophon legend.
    var plainLanguage: String {
        switch self {
        case .mit:
            "Use freely, commercial or not. Keep the copyright notice with the source."
        case .apache2:
            "Same as MIT, plus an explicit patent grant. The most common open-source license."
        case .ccBy4:
            "Free to use commercially. Attribution required — which is exactly what you're reading."
        }
    }
}
