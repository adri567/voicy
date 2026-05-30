import SwiftUI

struct EngineView: View {

    private let models: [EngineModel] = [
        EngineModel(
            id: "whisper-tiny",
            libraryID: "openai_whisper-tiny",
            family: .whisper,
            description: "The smallest model. Quick drafts, chat, casual notes. Stumbles on proper names and strong accents — but starts in a heartbeat.",
            size: "~75 MB",
            speed: "Real-time",
            accuracy: 0.74,
            highlight: nil
        ),
        EngineModel(
            id: "whisper-small",
            libraryID: "openai_whisper-small",
            family: .whisper,
            description: "The sweet spot. Handles German + English mid-sentence switches, light jargon, ordinary rooms.",
            size: "~500 MB",
            speed: "Medium",
            accuracy: 0.91,
            highlight: "Recommended for everyday dictation"
        ),
        EngineModel(
            id: "whisper-large-v3",
            libraryID: "openai_whisper-large-v3_947MB",
            family: .whisper,
            description: "The current state of the art. 99 languages, accented speech, noisy rooms, long-form editorial — at the price of a heavier footprint.",
            size: "~947 MB",
            speed: "Slow",
            accuracy: 0.97,
            highlight: "Best quality"
        ),
        EngineModel(
            id: "parakeet-v3",
            libraryID: "v3",
            family: .parakeet,
            description: "Lightning-fast streaming on the Apple Neural Engine. 25 European languages plus Japanese — particularly strong for German and French. Use it when latency matters most.",
            size: "~550 MB",
            speed: "Real-time",
            accuracy: 0.93,
            highlight: "Fastest for EU"
        ),
    ]

    @State private var viewModel = EngineViewModel()
    @State private var pendingSetDefault: EngineModel?
    @State private var pendingRemove: EngineModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.vertical, 32)

                library
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
        .onAppear {
            viewModel.refresh(
                whisperIDs: viewModel.whisperIDs(from: models),
                parakeetVersions: viewModel.parakeetVersions(from: models)
            )
        }
        .alert(
            "Activate model?",
            isPresented: Binding(
                get: { pendingSetDefault != nil },
                set: { if !$0 { pendingSetDefault = nil } }
            ),
            presenting: pendingSetDefault
        ) { model in
            Button("Cancel", role: .cancel) { pendingSetDefault = nil }
            Button("Restart now") {
                let m = model
                pendingSetDefault = nil
                viewModel.setAsDefault(family: m.asVMFamily, id: m.libraryID)
            }
        } message: { model in
            Text("Voicy will switch to \(model.name) and restart. Any active recording will be lost.")
        }
        .alert(
            "Delete model?",
            isPresented: Binding(
                get: { pendingRemove != nil },
                set: { if !$0 { pendingRemove = nil } }
            ),
            presenting: pendingRemove
        ) { model in
            Button("Cancel", role: .cancel) { pendingRemove = nil }
            Button("Delete", role: .destructive) {
                let m = model
                pendingRemove = nil
                Task { await viewModel.remove(family: m.asVMFamily, id: m.libraryID) }
            }
        } message: { model in
            if viewModel.statuses[model.libraryID] == .active {
                Text("\(model.name) is currently active. After deletion, recording won't work until you reinstall it.")
            } else {
                Text("Delete \(model.name)? You can reinstall it anytime.")
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    MetaLabel(text: "◆ The Editorial", color: DS.Palette.accent)
                    Text("Beta").dsTag()
                }
                .padding(.bottom, 14)

                Text("Pick the \(Text("voice").italic().foregroundColor(DS.Palette.accent))\nthat turns your speech into type.")
                    .font(DS.Font.serif(50))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                Text("Every model is a translator. Some are pedantic and slow; some are brisk and a little impressionistic. They all live on your machine — no audio leaves it.")
                    .font(DS.Font.sans(15))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 460, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            activeCard
                .frame(width: 360)
        }
    }

    private var activeCard: some View {
        let current = viewModel.activeModel(in: models)
        return VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Now serving", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            Text("\(Text(current.name).italic()) · \(current.tier)")
                .font(DS.Font.serif(36))
                .foregroundStyle(DS.Palette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.bottom, 6)

            Text("\(current.size) · loaded into RAM")
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.paper.opacity(0.7))
                .padding(.bottom, 22)

            EqualizerBars()
                .frame(height: 24)
                .padding(.bottom, 20)

            HStack(spacing: 16) {
                statBlock(label: "Accuracy", value: "\(Int(current.accuracy * 100))", suffix: "%")
                statBlock(label: "Latency",  value: current.speedNumber,             suffix: current.speedUnit)
            }
        }
        .padding(28)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 12)
    }

    private func statBlock(label: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            MetaLabel(text: label, color: DS.Palette.paper.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DS.Font.serif(28))
                    .foregroundStyle(DS.Palette.paper)
                Text(suffix)
                    .font(DS.Font.serif(16))
                    .foregroundStyle(DS.Palette.paper.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Library

    private var library: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("The \(Text("library").italic().foregroundColor(DS.Palette.ink))")
                    .font(DS.Font.serif(26))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink2)

                Spacer()
            }
            .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.sortedModels(models).enumerated()), id: \.element.id) { idx, model in
                    ModelRow(
                        model: model,
                        index: idx + 1,
                        first: idx == 0,
                        status: viewModel.statuses[model.libraryID] ?? .notInstalled,
                        onInstall: { Task { await viewModel.install(family: model.asVMFamily, id: model.libraryID) } },
                        onSetDefault: { pendingSetDefault = model },
                        onRemove: { pendingRemove = model }
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
            .dsPanel()

            DiarizationModelCard()
                .padding(.top, 24)
        }
    }
}
