import SwiftUI

struct MicrophoneScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            chapter: "01",
            kicker: "Chapter 01 — Permission",
            title: { titleView },
            lead: "Voicy needs access to your microphone to listen for dictation. Audio never leaves your Mac — transcription happens entirely on this device.",
            body: { bullets },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        (Text("First, ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
         + Text("let us hear you.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent))
        .tracking(-1.0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bullets: some View {
        VStack(spacing: 0) {
            OnboardingBulletRow(
                glyph: "🔒",
                label: "Stays on device",
                desc: "Audio is processed locally with the Whisper engine. Nothing is uploaded, ever."
            )
            OnboardingBulletRow(
                glyph: "◉",
                label: "Only when triggered",
                desc: "The mic is silent until you press your hotkey. No background listening."
            )
        }
    }

    private var footer: some View {
        NavFooter(
            primary: "Continue →",
            primaryDisabled: state.micPermission != .granted,
            onContinue: { state.next() },
            note: noteText
        )
    }

    private var noteText: String {
        switch state.micPermission {
        case .granted: return "Microphone authorised"
        case .denied:  return "Please enable microphone access to continue"
        case .idle:    return "Microphone access required"
        }
    }

    @ViewBuilder
    private var rightStage: some View {
        ZStack {
            // Concentric rings backdrop
            ForEach([60.0, 110.0, 170.0, 240.0], id: \.self) { r in
                Circle()
                    .stroke(DS.Palette.ink3.opacity(0.18), lineWidth: 0.7)
                    .frame(width: r * 2, height: r * 2)
            }
            .offset(y: -30)

            VStack(spacing: 28) {
                if state.micPermission == .denied {
                    deniedCard
                } else {
                    permissionDialog
                }
                statusPill
            }
        }
        .padding(40)
        .task {
            // Only ever upgrade the state to `.granted` from polling. `.denied`
            // must only land in state via the user clicking Allow (where the
            // request returns it explicitly) — otherwise a stale TCC denial
            // would suppress the native prompt before the user gets a chance
            // to ask for it.
            while !Task.isCancelled {
                if PermissionService.shared.currentMicrophoneState() == .granted,
                   state.micPermission != .granted {
                    state.micPermission = .granted
                }
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
    }

    private var deniedCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [
                        Color(red: 1.0, green: 0.973, blue: 0.91),
                        Color(red: 0.941, green: 0.894, blue: 0.769)
                    ], startPoint: .top, endPoint: .bottom))
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.365, green: 0.290, blue: 0.118))
            }
            .frame(width: 60, height: 60)

            Text("Microphone access blocked")
                .font(DS.Font.sans(14, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.114, green: 0.106, blue: 0.094))

            Text("macOS doesn't ask twice. Flip the Voicy toggle in System Settings → Privacy → Microphone, then return here.")
                .font(DS.Font.sans(11))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.114, green: 0.106, blue: 0.094).opacity(0.7))
                .padding(.horizontal, 8)

            Button(action: { PermissionService.shared.openMicrophonePane() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward.square")
                    Text("Open System Settings")
                }
                .font(DS.Font.sans(13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Color(red: 0.039, green: 0.42, blue: 1.0).opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 6)
                )
            }
            .buttonStyle(.plain)

            Text("If macOS asks you to quit & reopen Voicy, accept — onboarding resumes automatically.")
                .font(DS.Font.mono(10))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.114, green: 0.106, blue: 0.094).opacity(0.55))
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.961, green: 0.953, blue: 0.933).opacity(0.96))
        )
        .shadow(color: .black.opacity(0.28), radius: 30, y: 20)
    }

    private var permissionDialog: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [
                        Color(red: 1.0, green: 0.973, blue: 0.91),
                        Color(red: 0.941, green: 0.894, blue: 0.769)
                    ], startPoint: .top, endPoint: .bottom))
                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.365, green: 0.290, blue: 0.118))
            }
            .frame(width: 60, height: 60)

            Text("\u{201C}Voicy\u{201D} would like to access\nthe microphone.")
                .font(DS.Font.sans(14, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.114, green: 0.106, blue: 0.094))

            Text("Voicy uses your microphone to transcribe what you say into text at the cursor. Audio is processed on-device.")
                .font(DS.Font.sans(11))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.114, green: 0.106, blue: 0.094).opacity(0.65))
                .padding(.horizontal, 8)

            Divider().opacity(0.4)

            HStack(spacing: 8) {
                Button(action: { state.micPermission = .denied }) {
                    Text("Don't Allow")
                        .font(DS.Font.sans(13, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            state.micPermission == .denied
                            ? Color.black.opacity(0.05) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        let result = await PermissionService.shared.requestMicrophone()
                        state.micPermission = result
                    }
                }) {
                    Text("Allow")
                        .font(DS.Font.sans(13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            Color(red: 0.039, green: 0.42, blue: 1.0).opacity(0.92),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.961, green: 0.953, blue: 0.933).opacity(0.96))
        )
        .shadow(color: .black.opacity(0.28), radius: 30, y: 20)
    }

    @ViewBuilder
    private var statusPill: some View {
        switch state.micPermission {
        case .granted:
            Text("● Granted — Voicy can listen")
                .font(DS.Font.mono(10))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.902, green: 0.937, blue: 0.910))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DS.Palette.accent2, in: Capsule())
        case .denied:
            Text("○ Not granted yet")
                .dsTag()
        case .idle:
            Color.clear.frame(height: 28)
        }
    }
}
