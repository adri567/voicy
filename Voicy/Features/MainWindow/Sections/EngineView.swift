import SwiftUI

struct EngineView: View {

    // MOCK: only Whisper + Parakeet are real engines. The rest are visual
    // placeholders so the library design works end-to-end. TODO(engine-catalog).
    private let models: [EngineModel] = [
        EngineModel(
            id: "whisper",
            name: "Whisper Small",
            family: "OpenAI · Whisper",
            description: "Editorial-grade transcription with 99-language support. The default for nuanced speech and longer recordings.",
            size: "~500 MB",
            speed: "Medium",
            accuracy: 0.94,
            state: .availableInApp(realEngine: .whisper),
            highlight: "Recommended for editorial work"
        ),
        EngineModel(
            id: "parakeet",
            name: "Parakeet TDT v3",
            family: "NVIDIA · NeMo",
            description: "Streaming-fast on Apple Neural Engine. Built for real-time dictation with multilingual support.",
            size: "~470 MB",
            speed: "Real-time",
            accuracy: 0.91,
            state: .availableInApp(realEngine: .parakeet),
            highlight: nil
        ),
        EngineModel(
            id: "distil-en",
            name: "Distil-Whisper EN",
            family: "HuggingFace · Distil",
            description: "English-only distillation — six times faster than Large with near-identical accuracy on clean speech.",
            size: "756 MB",
            speed: "Fast",
            accuracy: 0.89,
            state: .mockAvailable,
            highlight: nil
        ),
        EngineModel(
            id: "voicy-edge",
            name: "Voicy Edge",
            family: "Voicy · in-house",
            description: "A 220 MB model tuned for short utterances and Apple Silicon. Lives entirely on device — no servers, ever.",
            size: "220 MB",
            speed: "Real-time",
            accuracy: 0.85,
            state: .mockDownloading(progress: 0.62),
            highlight: nil
        ),
        EngineModel(
            id: "whisper-turbo",
            name: "Whisper Turbo",
            family: "OpenAI · Whisper",
            description: "A newer distilled variant. Slightly faster than Medium, slightly less accurate on rare languages.",
            size: "1.62 GB",
            speed: "Fast",
            accuracy: 0.90,
            state: .mockAvailable,
            highlight: nil
        )
    ]

    @State private var selected: TranscriptionEngine = TranscriptionEngine.current
    @State private var pendingEngine: TranscriptionEngine?
    @State private var viewModel = EngineViewModel()
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
        .onAppear { viewModel.refresh() }
        .alert(
            "Engine wechseln?",
            isPresented: Binding(
                get: { pendingEngine != nil },
                set: { if !$0 { pendingEngine = nil } }
            ),
            presenting: pendingEngine
        ) { engine in
            Button("Abbrechen", role: .cancel) {
                pendingEngine = nil
            }
            Button("Jetzt neu starten") {
                TranscriptionEngine.current = engine
                AppRelauncher.relaunch()
            }
        } message: { engine in
            Text("Voicy wechselt zu \(engine.displayName) und startet neu. Eine laufende Aufnahme geht dabei verloren.")
        }
        .alert(
            "Modell löschen?",
            isPresented: Binding(
                get: { pendingRemove != nil },
                set: { if !$0 { pendingRemove = nil } }
            ),
            presenting: pendingRemove
        ) { _ in
            Button("Abbrechen", role: .cancel) { pendingRemove = nil }
            Button("Löschen", role: .destructive) {
                pendingRemove = nil
                Task { await viewModel.remove() }
            }
        } message: { model in
            if viewModel.status == .active {
                Text("\(model.name) ist aktuell aktiv. Nach dem Löschen kannst du nicht mehr aufnehmen, bis du es neu installierst.")
            } else {
                Text("\(model.name) löschen? Du kannst es jederzeit neu installieren.")
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ The Editorial", color: DS.Palette.accent)
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
                    .frame(maxWidth: 540, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            activeCard
                .frame(width: 360)
        }
    }

    private var activeCard: some View {
        let current = models.first { $0.realEngine == TranscriptionEngine.current } ?? models[0]

        return VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Now serving", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            Text("\(current.nameLeadingPart)\(Text(current.nameTrailingPart).italic())")
                .font(DS.Font.serif(36))
                .foregroundStyle(DS.Palette.paper)
                .padding(.bottom, 6)

            Text("\(current.family) · \(current.size) · loaded into RAM")
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.paper.opacity(0.7))
                .padding(.bottom, 22)

            EqualizerBars()
                .frame(height: 24)
                .padding(.bottom, 20)

            HStack(spacing: 16) {
                statBlock(label: "Accuracy", value: "\(Int(current.accuracy * 100))", suffix: "%")
                statBlock(label: "Latency",  value: current.speedNumber,            suffix: current.speedUnit)
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
                ForEach(Array(models.enumerated()), id: \.element.id) { idx, model in
                    ModelRow(
                        model: model,
                        index: idx + 1,
                        first: idx == 0,
                        isSelected: selected.rawValue == model.realEngine?.rawValue,
                        liveStatus: model.realEngine == TranscriptionEngine.current ? viewModel.status : nil,
                        onSelect: {
                            if let engine = model.realEngine, engine != selected {
                                pendingEngine = engine
                            }
                        },
                        onInstall: {
                            guard model.realEngine == TranscriptionEngine.current else { return }
                            Task { await viewModel.install() }
                        },
                        onRemove: {
                            guard model.realEngine == TranscriptionEngine.current else { return }
                            pendingRemove = model
                        }
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 8)
            .dsPanel()

            HStack {
                MetaLabel(text: "Looking for something exotic? Paste a Hugging Face URL.")
                Spacer()
                Button("Import model →") {
                    // TODO(import-model): not implemented
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

// MARK: - Equalizer

private struct EqualizerBars: View {
    @State private var phase: Double = 0
    private let heights: [Double] = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.8, 0.5, 0.6, 0.4, 0.7, 0.5, 0.3, 0.9, 0.6]

    var body: some View {
        TimelineView(.animation) { ctx in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<heights.count, id: \.self) { i in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let delay = Double(i) * 0.08
                    let speed = 1.0 + Double(i % 4) * 0.2
                    let phase = (t / speed + delay).truncatingRemainder(dividingBy: 1)
                    let amplitude = 0.3 + abs(sin(phase * .pi)) * 0.7
                    Capsule()
                        .fill(DS.Palette.paper)
                        .frame(width: 3, height: 24 * heights[i] * amplitude)
                }
            }
        }
    }
}

// MARK: - Model Row

private struct ModelRow: View {
    let model: EngineModel
    let index: Int
    let first: Bool
    let isSelected: Bool
    var liveStatus: EngineViewModel.Status? = nil
    let onSelect: () -> Void
    var onInstall: () -> Void = {}
    var onRemove: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                // Item number
                Text(String(format: "%02d", index))
                    .font(DS.Font.serifItalic(36))
                    .foregroundStyle(isSelected ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: 60, alignment: .leading)

                // Name + description
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(model.name)
                            .font(DS.Font.serif(28))
                            .tracking(-0.3)
                            .foregroundStyle(DS.Palette.ink)
                        MetaLabel(text: model.family)
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

                // Specs
                VStack(alignment: .leading, spacing: 6) {
                    specRow(label: "size",     value: model.size)
                    specRow(label: "speed",    value: model.speed)
                    specRow(label: "accuracy", value: nil, accuracy: model.accuracy)
                }
                .frame(width: 200)

                // Action
                actionBlock
                    .frame(width: 160, alignment: .trailing)
            }
            .padding(.vertical, 22)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
    }

    @ViewBuilder
    private var actionBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            badge

            if let liveStatus {
                liveActionBlock(status: liveStatus)
            } else {
                mockActionBlock
            }
        }
    }

    @ViewBuilder
    private func liveActionBlock(status: EngineViewModel.Status) -> some View {
        switch status {
        case .active:
            MetaLabel(text: "Loaded in RAM")
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

    @ViewBuilder
    private var mockActionBlock: some View {
        switch model.state {
        case .availableInApp(let engine):
            if engine == TranscriptionEngine.current {
                MetaLabel(text: "Loaded in RAM")
            } else {
                Button("Set active") { onSelect() }
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(11, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
            }
        case .mockAvailable:
            Button {
                // TODO(model-download): not implemented
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("Download")
                        .font(DS.Font.sans(11, weight: .semibold))
                }
                .foregroundStyle(DS.Palette.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DS.Palette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        case .mockDownloading(let progress):
            VStack(alignment: .trailing, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 6)
                        Capsule()
                            .fill(DS.Palette.accent)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
                Text("\(Int(progress * 100))% · 312 MB / 470 MB")
                    .font(DS.Font.mono(9))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(width: 140)
        }
    }

    private var badge: some View {
        let tuple: (String, Bool, Bool) = {
            if let liveStatus {
                switch liveStatus {
                case .active:        return ("In use",      false, true)
                case .downloading:   return ("Downloading", true,  false)
                case .notInstalled:  return ("Available",   false, false)
                }
            }
            switch model.state {
            case .availableInApp(let engine):
                return engine == TranscriptionEngine.current ? ("In use", false, true) : ("Installed", false, false)
            case .mockAvailable:    return ("Available", false, false)
            case .mockDownloading:  return ("Downloading", true, false)
            }
        }()
        return Text(tuple.0).dsTag(solid: tuple.1, accent: tuple.2)
    }

    private func specRow(label: String, value: String?, accuracy: Double? = nil) -> some View {
        HStack {
            MetaLabel(text: label)
            Spacer()
            if let value {
                Text(value).font(DS.Font.mono(11)).foregroundStyle(DS.Palette.ink)
            } else if let accuracy {
                HStack(spacing: 8) {
                    Text("\(Int(accuracy * 100))%")
                        .font(DS.Font.mono(11))
                        .foregroundStyle(DS.Palette.ink)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.1)).frame(height: 4)
                            Capsule().fill(DS.Palette.ink).frame(width: geo.size.width * accuracy, height: 4)
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            }
        }
    }
}

// MARK: - Model

private struct EngineModel: Identifiable {
    enum State {
        case availableInApp(realEngine: TranscriptionEngine)
        case mockAvailable
        case mockDownloading(progress: Double)
    }

    let id: String
    let name: String
    let family: String
    let description: String
    let size: String
    let speed: String
    let accuracy: Double
    let state: State
    let highlight: String?

    var realEngine: TranscriptionEngine? {
        if case .availableInApp(let engine) = state { return engine }
        return nil
    }

    // For the "now serving" headline italic split (e.g. "Whisper" + " Small")
    var nameLeadingPart: String {
        guard let space = name.firstIndex(of: " ") else { return name }
        return String(name[..<space])
    }
    var nameTrailingPart: String {
        guard let space = name.firstIndex(of: " ") else { return "" }
        return String(name[space...])
    }

    var speedNumber: String {
        switch speed {
        case "Real-time": "0.4"
        case "Fast":      "0.8"
        case "Medium":    "1.4"
        case "Slow":      "2.6"
        default:           "—"
        }
    }
    var speedUnit: String { "s" }
}
