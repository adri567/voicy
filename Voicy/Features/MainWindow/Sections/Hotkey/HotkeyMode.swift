enum HotkeyMode: String, CaseIterable, Hashable {
    case hold, toggle, double

    var title: String {
        switch self {
        case .hold:   "Hold"
        case .toggle: "Toggle"
        case .double: "Double-tap"
        }
    }
    var subtitle: String {
        switch self {
        case .hold:   "Press & hold"
        case .toggle: "Tap to start, tap to stop"
        case .double: "Two quick taps"
        }
    }
    var description: String {
        switch self {
        case .hold:   "The classic. Speak while the key is down; release to send."
        case .toggle: "Hands-free. Tap once to start, tap again when done."
        case .double: "Doesn't conflict with anything. Double-tap to arm, then dictate."
        }
    }
    var gesture: String {
        switch self {
        case .hold:   "press · speak · release"
        case .toggle: "tap · speak · tap"
        case .double: "tap·tap · speak"
        }
    }
}
