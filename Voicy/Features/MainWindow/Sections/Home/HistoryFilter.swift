enum HistoryFilter: CaseIterable, Hashable {
    case all, today, week

    var label: String {
        switch self {
        case .all:   "ALL"
        case .today: "TODAY"
        case .week:  "WEEK"
        }
    }
}
