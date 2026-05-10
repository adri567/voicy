import SwiftUI

struct OverlayView: View {

    var viewModel: RecordingViewModel

    var body: some View {
        stateContent
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: viewModel.state)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .loadingModel, .idle:
            Color.clear
                .frame(width: 40, height: 8)
                .pill()
                .transition(.scale(0.75, anchor: .bottom).combined(with: .opacity))

        case .recording:
            AnimatedWaveform(maxHeight: 17, level: viewModel.audioLevel)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .pill()
                .transition(.scale(0.75, anchor: .bottom).combined(with: .opacity))

        case .transcribing:
            TranscribingDotsView()
                .frame(width: 46, height: 17)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .pill()
                .transition(.scale(0.75, anchor: .bottom).combined(with: .opacity))
        }
    }
}

private extension View {
    func pill() -> some View {
        self
            .background(.black.opacity(0.8), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
    }
}
