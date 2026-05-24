import Testing
@testable import Voicy

@Suite("DownloadPhase")
struct DownloadPhaseTests {

    @Test("fraction is only set while downloading")
    func fraction() {
        #expect(DownloadPhase.preparing.fraction == nil)
        #expect(DownloadPhase.finalizing.fraction == nil)
        #expect(DownloadPhase.downloading(0.4).fraction == 0.4)
    }

    @Test("isIndeterminate true for preparing and finalizing")
    func indeterminate() {
        #expect(DownloadPhase.preparing.isIndeterminate)
        #expect(DownloadPhase.finalizing.isIndeterminate)
        #expect(!DownloadPhase.downloading(0.1).isIndeterminate)
    }

    @Test("shortLabel renders percent or phase text")
    func shortLabel() {
        #expect(DownloadPhase.preparing.shortLabel == "Connecting…")
        #expect(DownloadPhase.finalizing.shortLabel == "Finalizing…")
        #expect(DownloadPhase.downloading(0.42).shortLabel == "42%")
    }

    // MARK: - advanced(to:) monotonicity

    @Test("phases only move forward")
    func phasesMoveForward() {
        #expect(DownloadPhase.preparing.advanced(to: .downloading(0.3)) == .downloading(0.3))
        #expect(DownloadPhase.downloading(0.3).advanced(to: .finalizing) == .finalizing)
        // Backward transitions are ignored.
        #expect(DownloadPhase.finalizing.advanced(to: .downloading(0.9)) == .finalizing)
        #expect(DownloadPhase.downloading(0.5).advanced(to: .preparing) == .downloading(0.5))
    }

    @Test("fraction never regresses within downloading")
    func fractionMonotonic() {
        #expect(DownloadPhase.downloading(0.6).advanced(to: .downloading(0.4)) == .downloading(0.6))
        #expect(DownloadPhase.downloading(0.4).advanced(to: .downloading(0.7)) == .downloading(0.7))
    }
}
