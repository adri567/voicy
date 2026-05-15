import SwiftUI

struct ModelScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        ScreenShell(
            chapter: "03",
            kicker: "Chapter 03 — The Engine",
            title: AnyView(titleView),
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

private struct ModelCardView: View {
    let model: OnboardingModel
    let picked: Bool
    let dlPct: Double?
    let errorText: String?
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    radio
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            (Text(model.family + " ")
                                .font(DS.Font.serif(24, weight: .medium))
                             + Text(model.label)
                                .font(DS.Font.serifItalic(24, weight: .medium)))
                                .foregroundStyle(DS.Palette.ink)
                            Text(model.displaySize)
                                .font(DS.Font.mono(9))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(DS.Palette.ink3)
                        }

                        Text(model.body)
                            .font(DS.Font.sans(13))
                            .lineSpacing(3)
                            .foregroundStyle(DS.Palette.ink2)

                        HStack(spacing: 14) {
                            SpecBlock(label: "Word error", value: model.wer)
                            SpecBlock(label: "Speed", value: model.speed)
                        }
                    }
                    Spacer(minLength: 0)
                    if let pct = dlPct, pct >= 100 {
                        Text("● READY")
                            .font(DS.Font.mono(9))
                            .tracking(1.0)
                            .foregroundStyle(DS.Palette.accentInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DS.Palette.accent2, in: Capsule())
                    }
                }

                if let pct = dlPct, pct > 0 {
                    OnboardingProgressBar(value: pct)
                    HStack {
                        Text(pct >= 100 ? "Downloaded · verified" : "Downloading · \(Int(pct))%")
                        Spacer()
                        Text(pct >= 100 ? "Ready" : "\(Int(pct))% of \(model.displaySize)")
                    }
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                }
                if let errorText {
                    Text(errorText)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.accent)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(picked ? DS.Palette.paper : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(picked ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .shadow(color: .black.opacity(picked ? 0.08 : 0), radius: 18, y: 6)
            .overlay(alignment: .topTrailing) {
                if model.recommended {
                    Text("Recommended")
                        .font(DS.Font.mono(9))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.accentInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DS.Palette.accent, in: Capsule())
                        .offset(x: -18, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var radio: some View {
        ZStack {
            Circle()
                .stroke(picked ? DS.Palette.accent : DS.Palette.ink.opacity(0.25), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if picked {
                Circle()
                    .fill(DS.Palette.accent)
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.top, 4)
    }
}
