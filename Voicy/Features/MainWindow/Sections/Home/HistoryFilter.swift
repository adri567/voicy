enum HistoryFilter: CaseIterable, Hashable {
    case all, today, week, whisper, parakeet

    var label: String {
        switch self {
        case .all:      "ALL"
        case .today:    "TODAY"
        case .week:     "WEEK"
        case .whisper:  "WHISPER"
        case .parakeet: "PARAKEET"
        }
    }
}
