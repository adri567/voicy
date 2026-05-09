import SwiftUI

struct OverlayView: View {

    var viewModel: RecordingViewModel

    var body: some View {
        stateContent
            .animation(.spring(duration: 0.3), value: viewModel.state)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .loadingModel, .idle:
            Color.clear
                .frame(width: 30, height: 8)
                .pill()

        case .recording:
            AnimatedWaveform(maxHeight: 17)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .pill()

        case .transcribing:
            HStack(spacing: 8) {
                AnimatedWaveform(maxHeight: 17)
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
                    .tint(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .pill()
        }
    }
}

private extension View {
    func pill() -> some View {
        self
            .background(.black.opacity(0.65), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
    }
}
