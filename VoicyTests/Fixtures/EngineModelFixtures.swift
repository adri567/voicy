@testable import Voicy

/// Builds an `EngineModel` with defaults; only the fields the tests assert on
/// (libraryID, family) need to be passed. Display name/tier resolve from
/// `ModelCatalog` via the library ID, so they aren't passed here.
func engineModel(
    _ libraryID: String,
    family: EngineModel.Family = .whisper
) -> EngineModel {
    EngineModel(
        id: libraryID,
        libraryID: libraryID,
        family: family,
        description: "desc",
        size: "100 MB",
        speed: "Fast",
        accuracy: 0.9,
        highlight: nil
    )
}
