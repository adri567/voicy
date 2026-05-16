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
        (Text("Choose a ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
         + Text("voice.")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent))
        .tracking(-1.0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        let ready = state.modelDownload >= 100
        let primary: String = ready
            ? "Continue →"
            : "Continue (downloading \(state.pickedModel.label)) →"
        let note: String = ready
            ? "\(state.pickedModel.family) \(state.pickedModel.label) ready"
            : "\(Int(state.modelDownload))% of \(state.pickedModel.displaySize)"
        return NavFooter(
            primary: primary,
            onContinue: { state.next() },
            note: note
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
                        dlPct: state.modelID == model.id ? state.modelDownload : nil,
                        errorText: state.modelID == model.id ? state.modelDownloadError : nil,
                        onPick: {
                            state.selectAndDownloadModel(model)
                        }
                    )
                }
            }
            .padding(36)
        }
    }
}
