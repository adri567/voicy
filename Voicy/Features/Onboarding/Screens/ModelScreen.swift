import SwiftUI

struct ModelScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            chapter: "03",
            kicker: "Chapter 03 — The Engine",
            title: { titleView },
            lead: "Four engines, four trade-offs. Bigger Whisper means more accurate but heavier on disk and battery. Parakeet is the speed champion, English-first. You can swap anytime in Settings → Engine.",
            body: { EmptyView() },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        let lead = Text("Choose a ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
        let accent = Text("voice.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
        return Text("\(lead)\(accent)")
            .tracking(-1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        NavFooter(
            primary: state.modelPrimaryTitle,
            primaryDisabled: state.modelPrimaryDisabled,
            onContinue: { state.modelPrimaryAction() },
            note: state.modelFooterNote
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(OnboardingCatalog.models, id: \.id) { model in
                    ModelCardView(
                        model: model,
                        picked: state.modelID == model.id,
                        download: state.modelID == model.id ? state.modelState : nil,
                        onPick: {
                            state.selectModel(model)
                        }
                    )
                }
            }
            .padding(36)
        }
    }
}
