import SwiftUI

struct BrainView: View {

    private let models: [LLMModel] = [
        LLMModel(
            id: "gemma4-e2b",
            registryKey: "gemma4_e2b_it_4bit",
            name: "Gemma 4 E2B",
            family: "Google · MLX",
            description: "Compact instruction-tuned model running on Apple Silicon. Used for translation today, cleanup and snippets next. Lives entirely on device — no audio leaves your Mac.",
            size: "~1.1 GB",
            context: "8k",
            speed: "Fast",
            quality: 0.80,
            location: .local,
            highlight: "Recommended · running locally"
        ),
        LLMModel(
            id: "gemma4-e4b",
            registryKey: "gemma4_e4b_it_4bit",
            name: "Gemma 4 E4B",
            family: "Google · MLX",
            description: "The bigger sibling of Quill. Doubles disk and memory, noticeably better at longer reasoning and tone control.",
            size: "~2.2 GB",
            context: "8k",
            speed: "Medium",
            quality: 0.84,
            location: .local,
            highlight: nil
        ),
        LLMModel(
            id: "qwen2-5-7b",
            registryKey: "qwen2_5_7b",
            name: "Qwen 2.5 7B",
            family: "Alibaba · open weights",
            description: "Heavier and more thoughtful. 29-language support, exceptional for German, Slavic and Asian translations.",
            size: "~4 GB",
            context: "128k",
            speed: "Medium",
            quality: 0.91,
            location: .local,
            highlight: "Best multilingual premium"
        ),
        LLMModel(
            id: "claude-haiku-45",
            registryKey: nil,
            name: "Claude Haiku 4.5",
            family: "Anthropic",
            description: "Anthropic's small workhorse. Astonishing speed and quality for translation and rewriting. Coming soon — opt-in only.",
            size: "Cloud",
            context: "200k",
            speed: "Real-time",
            quality: 0.95,
            location: .cloud,
            highlight: nil
        ),
        LLMModel(
            id: "gpt-41-mini",
            registryKey: nil,
            name: "GPT-4.1 Mini",
            family: "OpenAI",
            description: "Quick, capable, ubiquitous. Best when you want the most polished tone, especially for English prose.",
            size: "Cloud",
            context: "128k",
            speed: "Real-time",
            quality: 0.94,
            location: .cloud,
            highlight: nil
        ),
        LLMModel(
            id: "gemini-25-flash",
            registryKey: nil,
            name: "Gemini 2.5 Flash",
            family: "Google",
            description: "Strong multilingual translation at a low cost. Useful if your three target languages span very different families.",
            size: "Cloud",
            context: "1M",
            speed: "Real-time",
            quality: 0.92,
            location: .cloud,
            highlight: nil
        ),
    ]

    @State private var viewModel = BrainViewModel()
    @State private var pendingSetDefault: LLMModel?
    @State private var pendingRemove: LLMModel?

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
        .onAppear { viewModel.refresh(registryKeys: viewModel.localRegistryKeys(from: models)) }
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
                let key = model.registryKey
                pendingSetDefault = nil
                if let key { viewModel.setAsDefault(registryKey: key) }
            }
        } message: { model in
            Text("Voicy will switch to \(model.displayName) and restart. Any active recording will be lost.")
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
                let key = model.registryKey
                pendingRemove = nil
                if let key { Task { await viewModel.remove(registryKey: key) } }
            }
        } message: { model in
            if let key = model.registryKey, viewModel.statuses[key] == .active {
                Text("\(model.displayName) is currently active. After deletion, translation won't work until you reinstall it.")
            } else {
                Text("Delete \(model.displayName)? You can reinstall it anytime.")
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ The Mind", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("The \(Text("brain").italic().foregroundColor(DS.Palette.accent)) behind the words.")
                    .font(DS.Font.serif(54))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                Text("Once your voice is text, a language model does the rest — translating, polishing, expanding snippets. Voicy can use a model on your Mac, or, when you opt in, a faster one in the cloud.")
                    .font(DS.Font.sans(16))
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
            MetaLabel(text: "Default model", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            activeCardTitle(for: current)
                .font(DS.Font.serif(32))
                .foregroundStyle(DS.Palette.paper)
                .padding(.bottom, 6)

            Text("\(current.size) · loaded into RAM")
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.paper.opacity(0.7))
                .padding(.bottom, 22)

            HStack(spacing: 18) {
                statBlock(label: "Quality", value: "\(Int(current.quality * 100))", suffix: "%")
                statBlock(label: "Latency", value: current.latencyNumber, suffix: "ms")
            }
            .padding(.bottom, 22)

            HStack(spacing: 10) {
                Circle()
                    .fill(Color(red: 0.29, green: 0.87, blue: 0.50))
                    .frame(width: 6, height: 6)
                Text("Running locally · no audio leaves your Mac")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.paper.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: DS.Radius.small))
        }
        .padding(28)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 12)
    }

    /// "Atlas · Pro" for local models, "Claude Haiku 4.5 · Anthropic · API" for cloud.
    private func activeCardTitle(for model: LLMModel) -> Text {
        let name = Text(model.displayName).italic()
        return Text("\(name) · \(model.tier ?? model.family)")
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

                HStack(spacing: 8) {
                    ForEach(LLMFilter.allCases) { f in
                        BrainFilterChip(
                            label: f.label,
                            isActive: viewModel.filter == f
                        ) { viewModel.filter = f }
                    }
                }
            }
            .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.visibleModels(models).enumerated()), id: \.element.id) { idx, model in
                    LLMRow(
                        model: model,
                        index: idx + 1,
                        first: idx == 0,
                        status: viewModel.status(of: model),
                        onInstall: {
                            guard let key = model.registryKey else { return }
                            Task { await viewModel.install(registryKey: key) }
                        },
                        onSetDefault: {
                            pendingSetDefault = model
                        },
                        onRemove: {
                            pendingRemove = model
                        }
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
            .dsPanel()
        }
    }
}
