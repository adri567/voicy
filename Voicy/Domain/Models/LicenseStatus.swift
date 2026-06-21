import Foundation

/// Lifecycle state of a Lemon Squeezy license key, mapped from the API's
/// `license_key.status`. For a subscription, `active` means it's paid and
/// current; `expired`/`disabled` mean it lapsed or was revoked (cancellation,
/// failed payment) and Pro should be withdrawn. `inactive` is a key that exists
/// but has never been activated.
nonisolated enum LicenseStatus: String, Sendable {
    case inactive
    case active
    case expired
    case disabled
}
