@testable import Voicy

/// Builds an `EngineModel` with defaults; only the fields the tests assert on
/// (libraryID, family) need to be passed.
func engineModel(
    _ libraryID: String,
    family: EngineModel.Family = .whisper,
    name: String = "Model X"
) -> EngineModel {
    EngineModel(
        id: libraryID,
        libraryID: libraryID,
        family: family,
        name: name,
        familyName: "Family",
        description: "desc",
        size: "100 MB",
        speed: "Fast",
        accuracy: 0.9,
        highlight: nil
    )
}
