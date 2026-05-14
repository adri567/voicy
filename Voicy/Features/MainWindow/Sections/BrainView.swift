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
            description: "The bigger sibling of E2B. Doubles disk and memory, noticeably better at longer reasoning and tone control.",
            size: "~2.2 GB",
            context: "8k",
            speed: "Medium",
            quality: 0.84,
            location: .local,
            highlight: nil
        ),
        LLMModel(
            id: "mistral-7b",
            registryKey: "mistral7B4bit",
            name: "Mistral 7B Instruct",
            family: "Mistral · open weights",
            description: "Lean and fast for its size. Solid multilingual translator with good European-language support. No reasoning overhead — outputs directly.",
            size: "~4 GB",
            context: "32k",
            speed: "Medium",
            quality: 0.85,
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
            id: "llama3-1-8b",
            registryKey: "llama3_1_8B_4bit",
            name: "Llama 3.1 8B",
            family: "Meta · open weights",
            description: "Meta's polished 8B instruction model. Strong general-purpose performer, declared multilingual support.",
            size: "~4.7 GB",
            context: "128k",
            speed: "Slow",
            quality: 0.88,
            location: .local,
            highlight: nil
        ),
        LLMModel(
            id: "claude-haiku-45",
            registryKey: nil,
            name: "Claude Haiku 4.5",
            family: "Anthropic · API",
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
            family: "OpenAI · API",
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
            family: "Google · API",
            description: "Strong multilingual translation at a low cost. Useful if your three target languages span very different families.",
            size: "Cloud",
            context: "1M",
            speed: "Real-time",
            quality: 0.92,
            location: .cloud,
            highlight: nil
        ),
    ]

    @State private var filter: LLMFilter = .all
    @State private var viewModel = BrainViewModel()
    @State private var pendingSetDefault: LLMModel?
    @State private var pendingRemove: LLMModel?

    private var localRegistryKeys: [String] {
        models.compactMap { $0.location == .local ? $0.registryKey : nil }
    }

    private var activeModel: LLMModel {
        let active = MLXTextCorrectionService.activeRegistryKey
        return models.first { $0.registryKey == active } ?? models[0]
    }

    private var visibleModels: [LLMModel] {
        models.filter { filter.matches($0, status: status(of: $0)) }
    }

    private func status(of model: LLMModel) -> BrainViewModel.Status? {
        guard let key = model.registryKey else { return nil }
        return viewModel.statuses[key]
    }

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
        .onAppear { viewModel.refresh(registryKeys: localRegistryKeys) }
        .alert(
            "Modell aktivieren?",
            isPresented: Binding(
                get: { pendingSetDefault != nil },
                set: { if !$0 { pendingSetDefault = nil } }
            ),
            presenting: pendingSetDefault
        ) { model in
            Button("Abbrechen", role: .cancel) { pendingSetDefault = nil }
            Button("Jetzt neu starten") {
                let key = model.registryKey
                pendingSetDefault = nil
                if let key { viewModel.setAsDefault(registryKey: key) }
            }
        } message: { model in
            Text("Voicy wechselt zu \(model.name) und startet neu. Eine laufende Aufnahme geht dabei verloren.")
        }
        .alert(
            "Modell löschen?",
            isPresented: Binding(
                get: { pendingRemove != nil },
                set: { if !$0 { pendingRemove = nil } }
            ),
            presenting: pendingRemove
        ) { model in
            Button("Abbrechen", role: .cancel) { pendingRemove = nil }
            Button("Löschen", role: .destructive) {
                let key = model.registryKey
                pendingRemove = nil
                if let key { Task { await viewModel.remove(registryKey: key) } }
            }
        } message: { model in
            if let key = model.registryKey, viewModel.statuses[key] == .active {
                Text("\(model.name) ist aktuell aktiv. Nach dem Löschen kannst du nicht mehr übersetzen, bis du es neu installierst.")
            } else {
                Text("\(model.name) löschen? Du kannst es jederzeit neu installieren.")
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
                    .frame(maxWidth: 560, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            activeCard
                .frame(width: 360)
        }
    }

    private var activeCard: some View {
        let current = activeModel
        return VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Default model", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            Text("\(current.nameLeadingPart)\(Text(current.nameTrailingPart).italic())")
                .font(DS.Font.serif(32))
                .foregroundStyle(DS.Palette.paper)
                .padding(.bottom, 6)

            Text("\(current.family) · \(current.size) · loaded into RAM")
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
                        FilterChip(
                            label: f.label,
                            isActive: filter == f
                        ) { filter = f }
                    }
                }
            }
            .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(visibleModels.enumerated()), id: \.element.id) { idx, model in
                    LLMRow(
                        model: model,
                        index: idx + 1,
                        first: idx == 0,
                        status: status(of: model),
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

            HStack {
                MetaLabel(text: "Got a GGUF or MLX model? Drop it on Voicy to install.")
                Spacer()
                Button("Import model →") {
                    // TODO(import-llm): not implemented
                }
                .buttonStyle(.plain)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
            }
            .padding(.top, 32)
        }
    }
}

// MARK: - Filter

private enum LLMFilter: String, CaseIterable, Identifiable {
    case all, local, cloud, installed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:       "All"
        case .local:     "Local"
        case .cloud:     "Cloud"
        case .installed: "Installed"
        }
    }

    func matches(_ model: LLMModel, status: BrainViewModel.Status?) -> Bool {
        switch self {
        case .all:       return true
        case .local:     return model.location == .local
        case .cloud:     return model.location == .cloud
        case .installed:
            guard let status else { return false }
            return status == .active || status == .installed
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(DS.Font.mono(10))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? DS.Palette.ink : Color.clear, in: Capsule())
                .overlay(
                    Capsule().stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LLM Row

private struct LLMRow: View {
    let model: LLMModel
    let index: Int
    let first: Bool
    let status: BrainViewModel.Status?
    let onInstall: () -> Void
    let onSetDefault: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                Text(String(format: "%02d", index))
                    .font(DS.Font.serifItalic(36))
                    .foregroundStyle(status == .active ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(model.name)
                            .font(DS.Font.serif(26))
                            .tracking(-0.3)
                            .foregroundStyle(DS.Palette.ink)
                        MetaLabel(text: model.family)
                        LocationChip(location: model.location)
                    }
                    Text(model.description)
                        .font(DS.Font.sans(14))
                        .lineSpacing(2)
                        .foregroundStyle(DS.Palette.ink2)
                        .frame(maxWidth: 560, alignment: .leading)
                    if let h = model.highlight {
                        Text("★ \(h)")
                            .font(DS.Font.mono(9))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(DS.Palette.accent)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    specRow(label: "size",    value: model.size)
                    specRow(label: "context", value: model.context)
                    specRow(label: "speed",   value: model.speed)
                    specRow(label: "quality", value: nil, quality: model.quality)
                }
                .frame(width: 200)

                actionBlock
                    .frame(width: 160, alignment: .trailing)
            }
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var actionBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            badge

            if model.location == .cloud {
                cloudComingSoon
            } else if let status {
                liveActionBlock(status: status)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func liveActionBlock(status: BrainViewModel.Status) -> some View {
        switch status {
        case .active:
            MetaLabel(text: "Loaded in RAM")
            TrashButton(onTap: onRemove)
        case .installed:
            Button("Set as default", action: onSetDefault)
                .buttonStyle(.plain)
                .font(DS.Font.sans(11, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
            TrashButton(onTap: onRemove)
        case .downloading(let fraction):
            ProgressBar(fraction: fraction)
                .frame(width: 140)
        case .notInstalled:
            Button(action: onInstall) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("Install")
                        .font(DS.Font.sans(11, weight: .semibold))
                }
                .foregroundStyle(DS.Palette.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DS.Palette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var cloudComingSoon: some View {
        Button("Notify me") {
            // TODO(brain-notify): cloud-model opt-in flow not implemented
        }
        .buttonStyle(.plain)
        .font(DS.Font.sans(11, weight: .medium))
        .foregroundStyle(DS.Palette.ink3)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .overlay(
            Capsule().strokeBorder(
                DS.Palette.ruleSoft,
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        )
    }

    private var badge: some View {
        let tuple: (String, Bool, Bool) = {
            if model.location == .cloud {
                return ("Coming soon", false, false)
            }
            switch status {
            case .active:        return ("In use",      false, true)
            case .installed:     return ("Installed",   false, false)
            case .downloading:   return ("Downloading", true,  false)
            case .notInstalled:  return ("Available",   false, false)
            case .none:          return ("Available",   false, false)
            }
        }()
        return Text(tuple.0).dsTag(solid: tuple.1, accent: tuple.2)
    }

    private func specRow(label: String, value: String?, quality: Double? = nil) -> some View {
        HStack {
            MetaLabel(text: label)
            Spacer()
            if let value {
                Text(value).font(DS.Font.mono(11)).foregroundStyle(DS.Palette.ink)
            } else if let quality {
                HStack(spacing: 8) {
                    Text("\(Int(quality * 100))%")
                        .font(DS.Font.mono(11))
                        .foregroundStyle(DS.Palette.ink)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.1)).frame(height: 4)
                            Capsule().fill(DS.Palette.ink).frame(width: geo.size.width * quality, height: 4)
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            }
        }
    }
}

// MARK: - Location Chip

private struct LocationChip: View {
    let location: LLMModel.Location

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
            Text(location == .cloud ? "Cloud" : "Local")
                .font(DS.Font.mono(9))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(background, in: Capsule())
        .overlay(Capsule().stroke(border, lineWidth: 1))
    }

    private var dotColor: Color {
        location == .cloud ? DS.Palette.accent2 : DS.Palette.ink2
    }
    private var textColor: Color {
        location == .cloud ? DS.Palette.accent2 : DS.Palette.ink2
    }
    private var background: Color {
        location == .cloud ? DS.Palette.accent2.opacity(0.10) : Color.black.opacity(0.05)
    }
    private var border: Color {
        location == .cloud ? DS.Palette.accent2.opacity(0.18) : DS.Palette.ruleSoft
    }
}

// MARK: - Model

private struct LLMModel: Identifiable {
    enum Location { case local, cloud }

    let id: String
    let registryKey: String?    // nil for cloud-only models
    let name: String
    let family: String
    let description: String
    let size: String
    let context: String
    let speed: String
    let quality: Double
    let location: Location
    let highlight: String?

    var nameLeadingPart: String {
        guard let space = name.firstIndex(of: " ") else { return name }
        return String(name[..<space])
    }
    var nameTrailingPart: String {
        guard let space = name.firstIndex(of: " ") else { return "" }
        return String(name[space...])
    }

    var latencyNumber: String {
        switch speed {
        case "Real-time": "300"
        case "Fast":      "500"
        case "Medium":    "800"
        case "Slow":      "1400"
        default:           "—"
        }
    }
}
