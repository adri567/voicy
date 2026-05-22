import SwiftUI

struct OnboardingView: View {
    @State private var state = OnboardingState()
    let viewModel: RecordingViewModel?
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Palette.paper)
        }
        .background(DS.Palette.paper2)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.rightArrow) {
            state.next()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            state.back()
            return .handled
        }
        .onAppear {
            // Refresh permission state on launch
            state.refreshPermissions()
        }
    }

    @ViewBuilder
    private var screen: some View {
        switch state.step {
        case .welcome:       WelcomeScreen(state: state)
        case .microphone:    MicrophoneScreen(state: state)
        case .accessibility: AccessibilityScreen(state: state)
        case .fnKey:         FnKeyScreen(state: state)
        case .model:         ModelScreen(state: state)
        case .brain:         BrainScreen(state: state)
        case .language:      LanguageScreen(state: state)
        case .practice:      PracticeScreen(state: state, viewModel: viewModel, onFinish: onFinish)
        }
    }
}
