import SwiftUI

struct OverlayView: View {

    var viewModel: RecordingViewModel
    var cycle: ModeCycleService

    private static let badgeSize: CGFloat = 25

    private var isRecording: Bool { viewModel.state == .recording }

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
                .animation(.spring(response: 0.45, dampingFraction: 0.72), value: viewModel.state)

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
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.0, anchor: .leading).combined(with: .opacity),
                                removal:   .scale(scale: 0.0, anchor: .leading).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        // Reserve vertical space for the brain-warning text *outside* the
        // pill+bubble HStack, so showing the warning never widens the row or
        // shifts the bubble. The slot is always present during recording —
        // only opacity flips.
        .padding(.top, isRecording ? 22 : 0)
        .overlay(alignment: .top) {
            if isRecording {
                Text("No AI model installed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 1.0, green: 0.73, blue: 0.2))
                    .fixedSize()
                    .opacity(brainWarning ? 1 : 0)
                    .animation(.easeOut(duration: 0.18), value: brainWarning)
                    .allowsHitTesting(false)
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

        case .noModel:
            errorAbovePill("No voice model installed")

        case .noBrain:
            errorAbovePill("No AI model installed")
        }
    }

    private func errorAbovePill(_ message: String) -> some View {
        VStack(spacing: 6) {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(red: 1.0, green: 0.73, blue: 0.2))
                .fixedSize()
            Color.clear
                .frame(width: 40, height: 8)
                .pill()
        }
        .transition(.scale(0.75, anchor: .bottom).combined(with: .opacity))
    }
}

private struct CycleBadge: View {
    let mode: Mode

    var body: some View {
        Group {
            if let emoji = mode.displayEmoji {
                Text(emoji)
                    .font(.system(size: 11))
            } else {
                // Raw / Developer / Email — render the type's glyph instead of
                // a flag/emoji. Sized to match the emoji bounds.
                Text(mode.type.glyph)
                    .font(.system(size: 10, weight: .medium, design: mode.type == .developer ? .monospaced : .serif))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 25, height: 25)
        .background(.black.opacity(0.8), in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
        .id(mode.id)
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
