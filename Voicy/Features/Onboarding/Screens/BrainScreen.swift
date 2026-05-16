import SwiftUI

struct BrainScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            chapter: "04",
            kicker: "Chapter 04 — Optional",
            title: { titleView },
            lead: nil,
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        (Text("And the ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
         + Text("brain")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
         + Text(" that polishes it.")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink))
        .tracking(-1.0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leftBody: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Once your voice is text, an optional language model can do more — translate live, clean up filler words, expand snippets, rewrite tone. **This step is optional** — skip it and Voicy still works as pure dictation.")
                .font(DS.Font.sans(16))
                .lineSpacing(4)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 460, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                MetaLabel(text: "What a brain unlocks")
                ForEach([
                    "Translate as you speak — German in, English out (or vice versa)",
                    "Tidy up filler words, false starts",
                    "Expand short snippets into your usual phrasings",
                    "Soften or sharpen tone after dictation"
                ], id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(DS.Palette.ink3)
                        Text(item)
                            .font(DS.Font.sans(13))
                            .lineSpacing(3)
                            .foregroundStyle(DS.Palette.ink2)
                    }
                }
            }
            .padding(20)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.panel).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
    }

    private var footer: some View {
        let picked = state.pickedBrain
        let primary: String = {
            if picked == nil { return "Continue without a brain →" }
            if state.brainDownload >= 100 { return "Continue →" }
            return "Continue while downloading →"
        }()
        let note: String = {
            if let b = picked { return "\(b.name) \(b.variant) · \(Int(state.brainDownload))%" }
            return "You can install one later in Settings → Brain"
        }()
        return NavFooter(
            primary: primary,
            onContinue: { state.next() },
            secondary: picked == nil ? nil : "Clear selection",
            onSkip: picked == nil ? nil : {
                state.brainID = nil
                state.brainDownload = 0
            },
            note: note
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Skip card
                Button(action: { state.brainID = nil; state.brainDownload = 0 }) {
                    HStack(alignment: .center, spacing: 14) {
                        radio(picked: state.brainID == nil)
                        VStack(alignment: .leading, spacing: 4) {
                            (Text("No brain for now ")
                                .font(DS.Font.serif(18, weight: .medium))
                                .foregroundStyle(DS.Palette.ink)
                             + Text("— just dictation")
                                .font(DS.Font.serifItalic(18))
                                .foregroundStyle(DS.Palette.ink3))
                            Text("Voicy will transcribe and paste. Skip the download, save the disk space. Add one anytime later.")
                                .font(DS.Font.sans(12))
                                .lineSpacing(3)
                                .foregroundStyle(DS.Palette.ink3)
                        }
                        Spacer()
                        Text("0 GB")
                            .font(DS.Font.mono(9))
                            .tracking(1.0)
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                state.brainID == nil ? DS.Palette.ink : DS.Palette.ruleSoft,
                                style: StrokeStyle(lineWidth: 1, dash: state.brainID == nil ? [] : [4, 4])
                            )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(state.brainID == nil ? DS.Palette.paper : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                MetaLabel(text: "Or — install one now")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                ForEach(OnboardingCatalog.brains, id: \.id) { brain in
                    BrainCardView(
                        brain: brain,
                        picked: state.brainID == brain.id,
                        dlPct: state.brainID == brain.id ? state.brainDownload : nil,
                        onPick: {
                            state.brainID = brain.id
                            state.brainDownload = 0
                        }
                    )
                }
            }
            .padding(36)
        }
        .task(id: "\(state.brainID ?? "none")-\(state.brainDownload)") {
            guard state.brainID != nil, state.brainDownload < 100 else { return }
            try? await Task.sleep(nanoseconds: 110_000_000)
            if !Task.isCancelled {
                state.brainDownload = min(100, state.brainDownload + Double.random(in: 1.5...5))
            }
        }
    }

    private func radio(picked: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(picked ? DS.Palette.accent : DS.Palette.ink.opacity(0.25), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if picked {
                Circle().fill(DS.Palette.accent).frame(width: 9, height: 9)
            }
        }
    }
}
