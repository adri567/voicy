import Foundation

/// UI-facing readiness of a brain that can't be installed/downloaded — today
/// only Apple's built-in on-device model. Lets the Brain UI render an
/// "available" or a reason-tagged "unavailable" state without importing
/// `FoundationModels`: the service maps the framework's availability into this.
nonisolated enum BrainAvailability: Equatable {
    case available
    /// Not usable right now; `reason` is a short, user-facing explanation.
    case unavailable(reason: String)

    var isAvailable: Bool { self == .available }
}
