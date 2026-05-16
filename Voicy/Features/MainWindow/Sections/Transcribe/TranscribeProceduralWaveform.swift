import Foundation

/// Procedural 96-bar waveform shape — port of the JS sine composition from
/// the design bundle (`voicy/project/components/TranscribeView.jsx`). Used by
/// both the live processing visual and the static file-player track so the
/// shape stays identical across stages.
nonisolated enum TranscribeProceduralWaveform {
    static let bars: [Double] = (0..<96).map { i in
        let x = Double(i)
        let a = sin(x * 0.31) * 0.5 + 0.55
        let b = sin(x * 0.11 + 1.2) * 0.25
        let c = sin(x * 0.74 + 0.4) * 0.15
        return max(0.08, min(1, a + b + c))
    }
}
