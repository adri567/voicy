import Foundation

struct TargetAppSnapshot: Sendable, Equatable {
    let bundleID: String?
    let appName: String?
    let windowTitle: String?
}

