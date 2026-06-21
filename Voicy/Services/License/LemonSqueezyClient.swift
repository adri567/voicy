import Foundation

/// Result of an activate/validate call against the Lemon Squeezy license API.
/// Defensively decoded — every field the app doesn't strictly need is optional,
/// so an unexpected payload degrades gracefully instead of throwing.
nonisolated struct LicenseValidation: Sendable {
    /// `activated` for activate, `valid` for validate.
    let valid: Bool
    let error: String?
    let status: LicenseStatus
    let instanceID: String?
    let storeID: Int?
    let variantID: Int?
    let customerEmail: String?
    let instanceName: String?
}

/// Network-level failures, distinct from business invalidity (which travels in
/// `LicenseValidation.error`).
nonisolated enum LemonSqueezyClientError: Error, Sendable {
    /// No connection, timeout, DNS — anything that prevented a reply.
    case transport(String)
    /// Reached the server but the reply wasn't usable JSON / had a bad status.
    case badResponse
}

/// Thin wrapper over the three public Lemon Squeezy license endpoints. They need
/// no API key — only the license key — so nothing secret is embedded in the app.
protocol LemonSqueezyClient: Sendable {
    func activate(key: String, instanceName: String) async throws -> LicenseValidation
    func validate(key: String, instanceID: String) async throws -> LicenseValidation
    func deactivate(key: String, instanceID: String) async throws
}
