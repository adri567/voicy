import SwiftUI

private let practiceSentence =
    "Voicy turns my voice into clean prose at the speed I think — and I never lift my hands from the table."

struct PracticeScreen: View {
    @Bindable var state: OnboardingState
    let viewModel: RecordingViewModel?
    let onFinish: () -> Void

    @FocusState private var noteFocus: Bool

    private var liveState: RecordingViewModel.RecordingState {
        viewModel?.state ?? .idle
    }

    private var isRecording: Bool { liveState == .recording }
    private var isTranscribing: Bool {
        liveState == .transcribing || liveState == .correcting
    }
    private var hasResult: Bool {
        !state.practiceText.isEmpty && liveState == .idle
    }

    var body: some View {
        ScreenShell(
            chapter: "06",
            kicker: "Chapter 06 — Trial run",
            title: { titleView },
            lead: nil,
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        let lead = Text("Now ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
        let accent = Text("say something.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
        return Text("\(lead)\(accent)")
            .tracking(-1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leftBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Place your cursor on the right and hold")
                        .font(DS.Font.sans(16))
                        .foregroundStyle(DS.Palette.ink2)
                    Kbd("fn", highlighted: true)
                    Text(".")
                        .font(DS.Font.sans(16))
                        .foregroundStyle(DS.Palette.ink2)
                }
                Text("Speak naturally — punctuation and casing are inferred from your tone. Release to paste.")
                    .font(DS.Font.sans(16))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 460, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                MetaLabel(text: "Try this — or anything else")
                Text("\u{201C}\(practiceSentence)\u{201D}")
                    .font(DS.Font.serifItalic(17))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
    }

    private var footer: some View {
        let note: String = {
            if isRecording { return "● Listening…" }
            if isTranscribing { return "… transcribing" }
            if hasResult { return "✓ Dictation succeeded" }
            return ""
        }()
        return NavFooter(
            primary: "Open Voicy →",
            primaryDisabled: false,
            onContinue: {
                state.persistFinalChoices()
                onFinish()
            },
            secondary: hasResult ? nil : "Skip practice",
            onSkip: hasResult ? nil : {
                state.persistFinalChoices()
                onFinish()
            },
            note: note
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetaLabel(text: "⌐ Notes — Untitled — edited just now")

            VStack(alignment: .leading, spacing: 14) {
                Text("First Try")
                    .font(DS.Font.serif(22, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)

                noteBody
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                HStack {
                    Spacer()
                    dictateButton
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )

            MetaLabel(text: "On real Voicy, your words paste into whichever app has focus. Here, into this notepad.")
        }
        .padding(36)
        .onAppear {
            // Start with an empty notepad each time the user lands on this
            // screen and grab focus so Voicy's Cmd+V paste lands here.
            state.practiceText = ""
            viewModel?.clearTranscript()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                noteFocus = true
            }
        }
    }

    @ViewBuilder
    private var noteBody: some View {
        // Editable text field — Voicy pastes via Cmd+V, which only lands in
        // the focused responder, so this needs to be a real input control.
        // The placeholder is overlaid manually because TextEditor doesn't
        // support prompts on macOS.
        ZStack(alignment: .topLeading) {
            if state.practiceText.isEmpty {
                Text("your words will appear here…")
                    .font(DS.Font.serifItalic(15))
                    .foregroundStyle(DS.Palette.ink3)
                    .lineSpacing(5)
                    .padding(.top, 6)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $state.practiceText)
                .font(DS.Font.serif(15))
                .lineSpacing(5)
                .foregroundStyle(DS.Palette.ink)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($noteFocus)
        }
    }

    private var dictateButton: some View {
        // Read-only status indicator. Recording is driven entirely by the
        // global Fn hotkey — the user is meant to actually practice the
        // gesture here, not click a button.
        HStack(spacing: 12) {
            Circle()
                .fill(isRecording ? DS.Palette.accentInk : Color(red: 1.0, green: 0.357, blue: 0.227))
                .frame(width: 9, height: 9)
            Group {
                if isRecording {
                    Text("Listening…")
                        .font(DS.Font.mono(11))
                } else if isTranscribing {
                    Text("Transcribing…")
                        .font(DS.Font.mono(11))
                } else if hasResult {
                    Text("Done — hold Fn to try again")
                        .font(DS.Font.mono(11))
                } else {
                    HStack(spacing: 6) {
                        Text("Hold").font(DS.Font.sans(12, weight: .medium))
                        OnboardingKbd(label: "fn", dark: true)
                        Text("to dictate").font(DS.Font.sans(12, weight: .medium))
                    }
                }
            }
            .foregroundStyle(isRecording ? DS.Palette.accentInk : DS.Palette.paper)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(isRecording ? DS.Palette.accent : DS.Palette.ink)
        )
    }
}
