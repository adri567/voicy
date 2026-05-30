import Foundation

/// Thrown by `withTimeout` when the operation outruns its deadline.
struct TimeoutError: Error, Equatable {}

/// Runs `operation`, throwing `TimeoutError` if it doesn't finish within
/// `duration`. The losing child task is cancelled, but cancellation is
/// cooperative: an operation that ignores it keeps running in the background
/// until it completes — only its result is discarded.
nonisolated func withTimeout<T: Sendable>(
    _ duration: Duration,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError()
        }
        defer { group.cancelAll() }
        return try await group.next()!
    }
}
