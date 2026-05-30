struct EngineModel: Identifiable {
    enum Family { case whisper, parakeet }

    let id: String
    let libraryID: String      // e.g. "openai_whisper-small" or "v3"
    let family: Family
    let description: String
    let size: String
    let speed: String
    let accuracy: Double
    let highlight: String?

    /// Voicy branding for this model, resolved from the central catalog.
    private var credit: ModelCredit? { ModelCatalog.engines[libraryID] }
    var name: String { credit?.voicyName ?? "Engine" }
    var tier: String { credit?.tier ?? "" }

    var asVMFamily: EngineViewModel.Family {
        switch family {
        case .whisper:  return .whisper
        case .parakeet: return .parakeet
        }
    }

    var speedNumber: String {
        switch speed {
        case "Real-time": "0.4"
        case "Fast":      "0.8"
        case "Medium":    "1.4"
        case "Slow":      "2.6"
        default:           "—"
        }
    }
    var speedUnit: String { "s" }
}
