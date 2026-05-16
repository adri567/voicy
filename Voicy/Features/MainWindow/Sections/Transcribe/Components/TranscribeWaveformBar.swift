import SwiftUI

struct TranscribeWaveformBar: View {
    let passed: Bool
    let animated: Bool
    let height: CGFloat
    let index: Int

    @State private var phase: CGFloat = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(height: height)
            .scaleEffect(y: shouldAnimate ? phase : 1, anchor: .center)
            .onAppear { startAnimationIfNeeded() }
    }

    private var barColor: Color {
        if passed { return DS.Palette.accent }
        return animated
            ? DS.Palette.ink3.opacity(0.4)
            : DS.Palette.ink.opacity(0.22)
    }

    private var shouldAnimate: Bool {
        animated && !passed
    }

    private func startAnimationIfNeeded() {
        guard shouldAnimate else { return }
        let period = 0.7 + Double(index % 4) * 0.15
        let delay  = Double(index) * 0.04
        withAnimation(
            .easeInOut(duration: period)
                .repeatForever(autoreverses: true)
                .delay(delay)
        ) {
            phase = 0.3
        }
    }
}
