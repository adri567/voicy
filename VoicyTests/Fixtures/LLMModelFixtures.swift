@testable import Voicy

/// Builds an `LLMModel` with defaults; only id, registryKey and location
/// matter for the BrainViewModel filter/sort tests.
func llmModel(
    _ id: String,
    registryKey: String? = nil,
    location: LLMModel.Location = .local,
    name: String = "LLM X"
) -> LLMModel {
    LLMModel(
        id: id,
        registryKey: registryKey,
        name: name,
        family: "Family",
        description: "desc",
        size: "1 GB",
        context: "8k",
        speed: "Fast",
        quality: 0.9,
        location: location,
        highlight: nil
    )
}
