import SwiftUI

struct OverlayView: View {

    var viewModel: RecordingViewModel
    var cycle: ModeCycleService

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let badgeSize: CGFloat = 25

    private var isRecording: Bool { viewModel.state == .recording }

    // Reduce Motion swaps the spring + scale choreography for plain opacity, so
    // the pill/badge appear and disappear without bounce or scaling. Identical
    // to the original for users who don't have Reduce Motion enabled.
    private var stateAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.72)
    }
    private var badgeAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 1.0)
    }
    private var pillTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.75, anchor: .bottom).combined(with: .opacity)
    }
    private var badgeTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0, anchor: .leading).combined(with: .opacity)
    }

    private var brainWarning: Bool {
        viewModel.state == .recording
        && cycle.activeMode.type != .raw
        && !viewModel.isBrainInstalled
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            // Mirror spacer on the leading side so the pill stays horizontally
            // centered within the window while a badge slot is reserved on the
            // trailing side.
            if isRecording {
                Color.clear
                    .frame(width: Self.badgeSize, height: 1)
            }

            stateContent
                .animation(stateAnimation, value: viewModel.state)

            // Fixed-size slot during recording: the window size doesn't change
            // when the cycle step toggles, so the badge can grow cleanly out of
            // the pill (from its leading edge) without the window itself
            // re-centering mid-animation. Raw mode = no badge — it's the
            // "no-op" default and shouldn't add visual noise.
            if isRecording {
                ZStack {
                    Color.clear
                        .frame(width: Self.badgeSize, height: Self.badgeSize)

                    if cycle.activeMode.type != .raw {
                        CycleBadge(mode: cycle.activeMode)
                            // Each mode gets its own SwiftUI identity so the
                            // old badge actually leaves (removal transition)
                            // and the new one enters (insertion transition)
                            // when the cycle advances — otherwise it's just
                            // a swap of arguments and the transition is silent.
                            .id(cycle.activeMode.id)
                            .transition(badgeTransition)
                    }
                }
            }
        }
        // Breathing room for spring-overshoot: the badge's scale exceeds 1.0
        // mid-bounce (dampingFraction 0.5), so without padding the NSPanel
        // clips the overshooting edges. Symmetric horizontally so the pill
        // stays centered; small bottom pad because top is already covered by
        // the warning-text reservation below.
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        // Reserve vertical space for the brain-warning text *outside* the
        // pill+bubble HStack, so showing the warning never widens the row or
        // shifts the bubble. The slot is always present during recording —
        // only opacity flips.
        .padding(.top, isRecording ? 22 : 0)
        .overlay(alignment: .top) {
            if isRecording {
                Text("No AI model installed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize()
                    .opacity(brainWarning ? 1 : 0)
                    .animation(.easeOut(duration: 0.18), value: brainWarning)
                    .allowsHitTesting(false)
            }
        }
        // Critically-damped spring: badge emerges smoothly to 100% without
        // overshooting — overshoot looked ungainly because the badge briefly
        // exceeded the pill height.
        .animation(badgeAnimation, value: cycle.step)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .loadingModel, .idle:
            Color.clear
                .frame(width: 40, height: 8)
                .pill()
                .transition(pillTransition)

        case .recording:
            AnimatedWaveform(maxHeight: 17, level: viewModel.audioLevel)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .pill()
                .transition(pillTransition)

        case .transcribing, .correcting:
            TranscribingDotsView()
                .frame(width: 46, height: 17)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .pill()
                .transition(pillTransition)

        case .noModel:
            errorAbovePill("No voice model installed")

        case .noBrain:
            errorAbovePill("No AI model installed")

        case .limitReached:
            errorAbovePill("Weekly limit reached")
        }
    }

    private func errorAbovePill(_ message: String) -> some View {
        VStack(spacing: 6) {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize()
            Color.clear
                .frame(width: 40, height: 8)
                .pill()
        }
        .transition(pillTransition)
    }
}

private extension View {
    func pill() -> some View {
        self
            .background(.black.opacity(0.8), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
    }
}
