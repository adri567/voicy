enum TriggerOption: String, CaseIterable, Identifiable, Hashable {
    case fn, rcmd, ralt, caps, custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fn:     "fn"
        case .rcmd:   "⌘"
        case .ralt:   "⌥"
        case .caps:   "⇪"
        case .custom: "Custom…"
        }
    }
    var description: String {
        switch self {
        case .fn:     "The Function key. Empty by default. The current default."
        case .rcmd:   "The right Command key. Easy to find without looking."
        case .ralt:   "The right Option key. Stays out of the way."
        case .caps:   "Caps Lock — for those who never use it anyway."
        case .custom: "Choose any combination — like ⇧ + Space."
        }
    }
}
