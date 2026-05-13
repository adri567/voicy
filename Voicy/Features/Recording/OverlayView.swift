import SwiftUI

struct OverlayView: View {

    var viewModel: RecordingViewModel
    var cycle: LanguageCycleService

    private static let badgeSize: CGFloat = 25

    private var isRecording: Bool { viewModel.state == .recording }

    var body: some View {
        HStack(spacing: 6) {
            // Mirror spacer on the leading side so the pill stays horizontally
            // centered within the window while a badge slot is reserved on the
            // trailing side.
            if isRecording {
                Color.clear
                    .frame(width: Self.badgeSize, height: 1)
            }

            stateContent
                .animation(.spring(response: 0.45, dampingFraction: 0.72), value: viewModel.state)

            // Fixed-size slot during recording: the window size doesn't change
            // when the cycle step toggles, so the badge can grow cleanly out of
            // the pill (from its leading edge) without the window itself
            // re-centering mid-animation.
            if isRecording {
                ZStack {
                    Color.clear
                        .frame(width: Self.badgeSize, height: Self.badgeSize)

                    if let target = cycle.activeTarget {
                        CycleBadge(language: target)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.0, anchor: .leading).combined(with: .opacity),
                                removal:   .scale(scale: 0.0, anchor: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: cycle.step)
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

        case .transcribing, .correcting:
            TranscribingDotsView()
                .frame(width: 46, height: 17)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .pill()
                .transition(.scale(0.75, anchor: .bottom).combined(with: .opacity))
        }
    }
}

private struct CycleBadge: View {
    let language: AppLanguage

    var body: some View {
        Text(language.flag)
            .font(.system(size: 11))
            .frame(width: 25, height: 25)
            .background(.black.opacity(0.8), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
            .id(language.code)
            .transition(.opacity.combined(with: .scale(0.6)))
    }
}

private extension View {
    func pill() -> some View {
        self
            .background(.black.opacity(0.8), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
    }
}
