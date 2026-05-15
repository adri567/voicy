import SwiftUI

struct EngineView: View {

    private let models: [EngineModel] = [
        EngineModel(
            id: "whisper-tiny",
            libraryID: "openai_whisper-tiny",
            family: .whisper,
            name: "Whisper Tiny",
            familyName: "OpenAI · Whisper",
            description: "The smallest Whisper — fits on a phone, runs in real-time on Apple Silicon. Good for short utterances and battery-conscious sessions.",
            size: "~75 MB",
            speed: "Real-time",
            accuracy: 0.74,
            highlight: nil
        ),
        EngineModel(
            id: "whisper-small",
            libraryID: "openai_whisper-small",
            family: .whisper,
            name: "Whisper Small",
            familyName: "OpenAI · Whisper",
            description: "The recommended default. Editorial-grade transcription across 99 languages, balanced for speed and accuracy.",
            size: "~500 MB",
            speed: "Medium",
            accuracy: 0.91,
            highlight: "Recommended"
        ),
        EngineModel(
            id: "whisper-large-v3-compact",
            libraryID: "openai_whisper-large-v3-v20240930_626MB",
            family: .whisper,
            name: "Whisper Large v3 Compact",
            familyName: "OpenAI · Whisper",
            description: "Premium accuracy in a 626 MB footprint. The 2024-09-30 large-v3 distillation tuned for Apple Silicon.",
            size: "~626 MB",
            speed: "Slow",
            accuracy: 0.95,
            highlight: nil
        ),
        EngineModel(
            id: "whisper-large-v3",
            libraryID: "openai_whisper-large-v3_947MB",
            family: .whisper,
            name: "Whisper Large v3",
            familyName: "OpenAI · Whisper",
            description: "The highest-quality OpenAI Whisper available locally. For when you want the words exactly right and don't mind waiting half a second more.",
            size: "~947 MB",
            speed: "Slow",
            accuracy: 0.97,
            highlight: "Best quality"
        ),
        EngineModel(
            id: "parakeet-v3",
            libraryID: "v3",
            family: .parakeet,
            name: "Parakeet v3",
            familyName: "NVIDIA · FluidAudio",
            description: "Streaming-fast on the Apple Neural Engine. 25 European languages — particularly strong for German, English, French.",
            size: "~550 MB",
            speed: "Real-time",
            accuracy: 0.93,
            highlight: "Fastest for EU"
        ),
    ]

    @State private var viewModel = EngineViewModel()
    @State private var pendingSetDefault: EngineModel?
    @State private var pendingRemove: EngineModel?

    private var whisperIDs: [String] { models.filter { $0.family == .whisper }.map(\.libraryID) }
    private var parakeetVersions: [String] { models.filter { $0.family == .parakeet }.map(\.libraryID) }

    private var activeModel: EngineModel {
        let activeID: String
        switch TranscriptionEngine.current {
        case .whisper:  activeID = DefaultTranscriptionService.activeModelID
        case .parakeet: activeID = ParakeetTranscriptionService.activeVersion
        }
        return models.first { $0.libraryID == activeID } ?? models[1]
    }

    private var sortedModels: [EngineModel] {
        models.enumerated().sorted { lhs, rhs in
            let lp = statusPriority(viewModel.statuses[lhs.element.libraryID] ?? .notInstalled)
            let rp = statusPriority(viewModel.statuses[rhs.element.libraryID] ?? .notInstalled)
            if lp != rp { return lp < rp }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func statusPriority(_ status: EngineViewModel.Status) -> Int {
        switch status {
        case .active:       return 0
        case .installed:    return 1
        case .downloading:  return 2
        case .notInstalled: return 3
        }
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
        .onAppear {
            viewModel.refresh(whisperIDs: whisperIDs, parakeetVersions: parakeetVersions)
        }
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
                let m = model
                pendingSetDefault = nil
                viewModel.setAsDefault(family: m.asVMFamily, id: m.libraryID)
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
                let m = model
                pendingRemove = nil
                Task { await viewModel.remove(family: m.asVMFamily, id: m.libraryID) }
            }
        } message: { model in
            if viewModel.statuses[model.libraryID] == .active {
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
        let current = activeModel
        return VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Now serving", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            Text("\(current.nameLeadingPart)\(Text(current.nameTrailingPart).italic())")
                .font(DS.Font.serif(36))
                .foregroundStyle(DS.Palette.paper)
                .padding(.bottom, 6)

            Text("\(current.familyName) · \(current.size) · loaded into RAM")
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
                ForEach(Array(sortedModels.enumerated()), id: \.element.id) { idx, model in
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
    let status: EngineViewModel.Status
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
                        MetaLabel(text: model.familyName)
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
                    specRow(label: "size",     value: model.size)
                    specRow(label: "speed",    value: model.speed)
                    specRow(label: "accuracy", value: nil, accuracy: model.accuracy)
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
    }

    private var badge: some View {
        let tuple: (String, Bool, Bool) = {
            switch status {
            case .active:        return ("In use",      false, true)
            case .installed:     return ("Installed",   false, false)
            case .downloading:   return ("Downloading", true,  false)
            case .notInstalled:  return ("Available",   false, false)
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
    enum Family { case whisper, parakeet }

    let id: String
    let libraryID: String      // e.g. "openai_whisper-small" or "v3"
    let family: Family
    let name: String
    let familyName: String     // e.g. "OpenAI · Whisper"
    let description: String
    let size: String
    let speed: String
    let accuracy: Double
    let highlight: String?

    var asVMFamily: EngineViewModel.Family {
        switch family {
        case .whisper:  return .whisper
        case .parakeet: return .parakeet
        }
    }

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
