import Foundation

/// Read-only view of the stored license for the Settings UI, built from the
/// last activation/validation response. Holds nothing secret — the key itself
/// stays in the Keychain.
nonisolated struct LicenseSnapshot: Sendable, Equatable {
    let status: LicenseStatus
    let customerEmail: String?
    let activationName: String?
}
