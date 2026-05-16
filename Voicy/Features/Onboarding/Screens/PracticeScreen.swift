import SwiftUI

private let practiceSentence =
    "Voicy turns my voice into clean prose at the speed I think — and I never lift my hands from the table."

struct PracticeScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            chapter: "06",
            kicker: "Chapter 06 — Trial run",
            title: AnyView(titleView),
            lead: nil,
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        (Text("Now ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
         + Text("say something.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent))
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
        let done = state.practicePhase == .done
        let recording = state.practicePhase == .recording
        return NavFooter(
            primary: done ? "Wonderful — Continue →" : "Continue →",
            primaryDisabled: !done,
            onContinue: { state.next() },
            secondary: done ? nil : "Skip practice",
            onSkip: done ? nil : { state.next() },
            note: recording ? "● Listening…" : (done ? "✓ Dictation succeeded" : "")
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
        .task(id: state.practicePhase) {
            // Animate the demo transcription character-by-character.
            guard state.practicePhase == .recording else { return }
            state.practiceText = ""
            for i in 0..<practiceSentence.count {
                try? await Task.sleep(nanoseconds: 22_000_000)
                if Task.isCancelled { break }
                state.practiceText = String(practiceSentence.prefix(i + 1))
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            if !Task.isCancelled, state.practicePhase == .recording {
                state.practicePhase = .done
            }
        }
    }

    @ViewBuilder
    private var noteBody: some View {
        let textColor = DS.Palette.ink
        if state.practicePhase == .idle {
            Text("your words will appear here…")
                .font(DS.Font.serifItalic(15))
                .foregroundStyle(DS.Palette.ink3)
                .lineSpacing(5)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(state.practiceText)
                    .font(DS.Font.serif(15))
                    .lineSpacing(5)
                    .foregroundStyle(textColor)
                if state.practicePhase != .done {
                    Rectangle()
                        .fill(DS.Palette.accent)
                        .frame(width: 2, height: 18)
                        .offset(x: 2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var dictateButton: some View {
        Button(action: {
            if state.practicePhase == .idle || state.practicePhase == .done {
                state.practicePhase = .recording
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(state.practicePhase == .recording ? DS.Palette.accentInk : Color(red: 1.0, green: 0.357, blue: 0.227))
                    .frame(width: 9, height: 9)
                Group {
                    switch state.practicePhase {
                    case .recording:
                        Text("Listening · \(min(30, state.practiceText.count / 9))s")
                            .font(DS.Font.mono(11))
                    case .done:
                        Text("Done — tap to try again")
                            .font(DS.Font.mono(11))
                    case .idle:
                        HStack(spacing: 6) {
                            Text("Hold").font(DS.Font.sans(12, weight: .medium))
                            OnboardingKbd(label: "fn", dark: true)
                            Text("to dictate").font(DS.Font.sans(12, weight: .medium))
                        }
                    }
                }
                .foregroundStyle(state.practicePhase == .recording ? DS.Palette.accentInk : DS.Palette.paper)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(state.practicePhase == .recording ? DS.Palette.accent : DS.Palette.ink)
            )
        }
        .buttonStyle(.plain)
    }
}
