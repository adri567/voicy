import Foundation

/// The user's subscription tier. `free` is the default on first launch; `pro`
/// is granted by the entitlement source (a local flag today, a Lemon Squeezy
/// license check later).
nonisolated enum Plan: String, Codable, Sendable {
    case free
    case pro
}
