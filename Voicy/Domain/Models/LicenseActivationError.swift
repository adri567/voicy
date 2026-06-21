import Foundation

/// Why a license activation failed, with a user-facing `message`. The `network`
/// and `server` cases carry the underlying detail for logging without leaking
/// it into the headline shown to the user.
nonisolated enum LicenseActivationError: Error, Sendable, Equatable {
    case invalidKey
    case activationLimitReached
    case wrongProduct
    case network(String)
    case server(String)

    var message: String {
        switch self {
        case .invalidKey:
            "That license key wasn't recognised. Check it and try again."
        case .activationLimitReached:
            "This license is already active on another device. Deactivate it there first."
        case .wrongProduct:
            "That key belongs to a different product."
        case .network:
            "Couldn't reach the licensing server. Check your connection and try again."
        case .server:
            "The licensing server returned an unexpected response. Please try again later."
        }
    }
}
