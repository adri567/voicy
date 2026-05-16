enum LLMFilter: String, CaseIterable, Identifiable {
    case all, local, cloud, installed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:       "All"
        case .local:     "Local"
        case .cloud:     "Cloud"
        case .installed: "Installed"
        }
    }

    func matches(_ model: LLMModel, status: BrainViewModel.Status?) -> Bool {
        switch self {
        case .all:       return true
        case .local:     return model.location == .local
        case .cloud:     return model.location == .cloud
        case .installed:
            guard let status else { return false }
            return status == .active || status == .installed
        }
    }
}
