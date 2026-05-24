import Foundation

/// One coherent model-download progress signal, shared by every install path
/// (Engine, Brain, Diarization). Replaces the bare `Double` that could not
/// distinguish "no measurable progress yet" from "0 % downloaded".
///
/// Lifecycle: `.preparing` → `.downloading(0…1)` → `.finalizing`. Not every
/// backend visits every case — Whisper/Parakeet library installs skip
/// `.finalizing` (no RAM-load), while MLX and Diarization surface it for the
/// CoreML/GPU compile that runs after the last byte arrives.
nonisolated enum DownloadPhase: Equatable, Sendable {
    /// Request issued, nothing measurable yet (HTTP handshake, file listing).
    case preparing
    /// Real byte progress, `0…1`.
    case downloading(Double)
    /// Bytes are on disk; the model is being compiled/loaded into RAM. No
    /// measurable fraction — the UI shows an indeterminate indicator.
    case finalizing

    /// Measurable fraction `0…1`, or `nil` when the phase is indeterminate
    /// (`.preparing`/`.finalizing`).
    var fraction: Double? {
        if case .downloading(let value) = self { return value }
        return nil
    }

    /// `true` when there is no measurable fraction to show — the UI should
    /// render a pulsing/indeterminate bar rather than a filled one.
    var isIndeterminate: Bool { fraction == nil }

    /// Compact human-facing label for the current phase, e.g. "42%",
    /// "Connecting…", "Finalizing…".
    var shortLabel: String {
        switch self {
        case .preparing:              return "Connecting…"
        case .downloading(let value): return "\(Int(max(0, min(value, 1)) * 100))%"
        case .finalizing:             return "Finalizing…"
        }
    }

    /// Monotonic update: phases only ever move forward, and within
    /// `.downloading` the fraction never regresses. Guards against late or
    /// out-of-order callbacks from the download libraries (which can re-emit a
    /// lower `fractionCompleted` mid-stream).
    func advanced(to next: DownloadPhase) -> DownloadPhase {
        guard rank == next.rank else {
            return next.rank > rank ? next : self
        }
        if case .downloading(let current) = self,
           case .downloading(let proposed) = next {
            return .downloading(max(current, proposed))
        }
        return next
    }

    private var rank: Int {
        switch self {
        case .preparing:   0
        case .downloading: 1
        case .finalizing:  2
        }
    }
}
