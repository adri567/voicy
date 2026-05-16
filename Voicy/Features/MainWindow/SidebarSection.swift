enum SidebarSection: String, CaseIterable, Identifiable {
    case home, snippets, engine, brain, modes, hotkey, settings
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     "Home"
        case .snippets: "Snippets"
        case .engine:   "Engine"
        case .brain:    "Brain"
        case .modes:    "Modes"
        case .hotkey:   "Hotkey"
        case .settings: "Settings"
        }
    }

    var hint: String {
        switch self {
        case .home:     "Verlauf"
        case .snippets: "Shortcuts"
        case .engine:   "Voice models"
        case .brain:    "Language models"
        case .modes:    "Slots"
        case .hotkey:   "Trigger"
        case .settings: "Preferences"
        }
    }

    var systemImage: String {
        switch self {
        case .home:     "house"
        case .snippets: "doc.on.doc"
        case .engine:   "gearshape.2"
        case .brain:    "brain"
        case .modes:    "character.bubble"
        case .hotkey:   "keyboard"
        case .settings: "slider.horizontal.3"
        }
    }
}
