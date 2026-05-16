struct LLMModel: Identifiable {
    enum Location { case local, cloud }

    let id: String
    let registryKey: String?    // nil for cloud-only models
    let name: String
    let family: String
    let description: String
    let size: String
    let context: String
    let speed: String
    let quality: Double
    let location: Location
    let highlight: String?

    var nameLeadingPart: String {
        guard let space = name.firstIndex(of: " ") else { return name }
        return String(name[..<space])
    }
    var nameTrailingPart: String {
        guard let space = name.firstIndex(of: " ") else { return "" }
        return String(name[space...])
    }

    var latencyNumber: String {
        switch speed {
        case "Real-time": "300"
        case "Fast":      "500"
        case "Medium":    "800"
        case "Slow":      "1400"
        default:           "—"
        }
    }
}
