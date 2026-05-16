import SwiftUI

// MARK: - Sample input/outputs

/// The single sentence rendered through every slot in the "One sentence,
/// every mode" panel. Designed to make the difference between modes legible
/// at a glance (statement + scheduling request).
private enum ModesSample {
    static let inputCode = "de"
    static let input = "Können wir das Meeting auf nächste Woche verschieben? Mir ist heute etwas dazwischen gekommen."
    static let developer = "Pushing the sync to next week — got pulled into something today."
    static let email = """
    Hi team,

    Would it be possible to push our meeting to next week? Something unexpected came up on my end today, and I'd like to give the discussion the attention it deserves.

    Thanks,
    """
    static let customFallback = "hey — can we move the mtg to next wk? smth came up today 🙏"
    static let snippetsSample = "Können wir das Meeting auf nächste Woche verschieben? Mir ist heute etwas dazwischen gekommen. Beste Grüße, Adrian"

    static func translate(target: String) -> String {
        switch target {
        case "en": return "Could we push the meeting to next week? Something came up on my end today."
        case "fr": return "Pourrions-nous reporter la réunion à la semaine prochaine ? Un imprévu m'est arrivé aujourd'hui."
        case "es": return "¿Podríamos posponer la reunión a la próxima semana? Hoy me ha surgido un imprevisto."
        case "it": return "Possiamo spostare la riunione alla prossima settimana? Oggi mi è capitato un imprevisto."
        case "nl": return "Kunnen we de meeting verplaatsen naar volgende week? Er kwam vandaag iets tussen."
        case "pt": return "Podemos adiar a reunião para a próxima semana? Surgiu algo do meu lado hoje."
        case "pl": return "Czy moglibyśmy przełożyć spotkanie na przyszły tydzień? Coś mi dziś wypadło."
        case "sv": return "Kan vi flytta mötet till nästa vecka? Det dök upp något hos mig idag."
        case "tr": return "Toplantıyı önümüzdeki haftaya alabilir miyiz? Bugün acil bir işim çıktı."
        case "de": return ModesSample.input
        default: return "[Sample translation to \(target.uppercased()) appears here when this mode runs.]"
        }
    }

    static func output(for mode: Mode) -> String {
        switch mode.type {
        case .raw:       return input
        case .translate: return translate(target: mode.targetCode ?? "en")
        case .developer: return developer
        case .email:     return email
        case .snippets:  return snippetsSample
        case .custom:    return customFallback
        }
    }
}

// MARK: - ModesView

struct ModesView: View {

    @Bindable var cycle: ModeCycleService

    @State private var activeID: UUID?

    private var activeMode: Mode {
        if let id = activeID, let m = cycle.modes.first(where: { $0.id == id }) {
            return m
        }
        return cycle.modes[cycle.step]
    }

    private var activeIndex: Int {
        cycle.modes.firstIndex(where: { $0.id == activeMode.id }) ?? cycle.step
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)
                    .padding(.bottom, 32)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)

                reelSection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, 32)
                    .padding(.bottom, 36)

                editorSection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 36)

                sampleSection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
        .onAppear {
            if activeID == nil { activeID = cycle.modes[cycle.step].id }
        }
        .onChange(of: cycle.modes.map(\.id)) { _, ids in
            // If the active slot was removed, fall back to the cycle's current
            // slot so the editor never points to a non-existent UUID.
            if let id = activeID, !ids.contains(id) {
                activeID = cycle.modes[cycle.step].id
            }
        }
    }

    // MARK: Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ The Atelier", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("Speak once.\nLand in \(Text("any voice.").italic().foregroundColor(DS.Palette.accent))")
                    .font(DS.Font.serif(54))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                instructionParagraph
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 560, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ActiveModeCard(
                mode: activeMode,
                index: activeIndex,
                total: cycle.modes.count,
                sourceLanguage: cycle.sourceLanguage
            )
            .frame(width: 380)
        }
    }

    private var instructionParagraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(instructionLead)
                .font(DS.Font.sans(16))
                .lineSpacing(4)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Cycle through with")
                    .font(DS.Font.sans(16))
                Kbd("fn", highlighted: true)
                Text("+")
                    .font(DS.Font.sans(16))
                Kbd("←")
                Kbd("→")
                Text("while dictating.")
                    .font(DS.Font.sans(16))
            }
        }
    }

    private var instructionLead: AttributedString {
        var attr = AttributedString("A ")
        var modeWord = AttributedString("Mode")
        modeWord.font = .system(.body, design: .serif).italic()
        modeWord.foregroundColor = DS.Palette.ink
        attr += modeWord
        attr += AttributedString(" is one way your transcription gets transformed before it lands. Line up ")
        var four = AttributedString("four to six")
        four.font = .system(.body, design: .serif).italic()
        four.foregroundColor = DS.Palette.ink
        attr += four
        attr += AttributedString(" of them — raw, translated, rewritten as an email, anything.")
        return attr
    }
}

// MARK: - Reel

private extension ModesView {
    var reelSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your \(Text("reel").italic())")
                    .font(DS.Font.serif(26))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink2)
                Spacer()
                MetaLabel(text: "\(cycle.modes.count) of \(ModeCycleService.maxSlots) slots · cycle bidirectionally")
            }
            .padding(.bottom, 20)

            VStack(spacing: 18) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(Array(cycle.modes.enumerated()), id: \.element.id) { idx, mode in
                            ModeSlotCard(
                                mode: mode,
                                index: idx,
                                isActive: mode.id == activeMode.id,
                                sourceLanguage: cycle.sourceLanguage
                            ) {
                                activeID = mode.id
                                cycle.setStep(idx)
                            }
                        }

                        AddSlotButton(disabled: cycle.modes.count >= ModeCycleService.maxSlots) {
                            if let new = cycle.addMode() {
                                activeID = new.id
                                cycle.setStep(cycle.modes.count - 1)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                SoftDivider()

                HStack {
                    HStack(spacing: 10) {
                        MetaLabel(text: "While recording")
                        HStack(spacing: 4) {
                            Kbd("fn", highlighted: true)
                            Text("+")
                                .font(DS.Font.mono(11))
                                .foregroundStyle(DS.Palette.ink3)
                            Kbd("←")
                            Kbd("→")
                        }
                        Text("steps the cursor through your reel — wraps at both ends.")
                            .font(DS.Font.sans(12))
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(Array(cycle.modes.enumerated()), id: \.element.id) { idx, mode in
                            Circle()
                                .fill(mode.id == activeMode.id ? DS.Palette.accent : DS.Palette.ink.opacity(0.18))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    activeID = mode.id
                                    cycle.setStep(idx)
                                }
                        }
                    }
                }
            }
            .padding(24)
            .dsPanel()
        }
    }
}

// MARK: - Editor section

private extension ModesView {
    var editorSection: some View {
        SlotEditor(
            mode: activeMode,
            index: activeIndex,
            total: cycle.modes.count,
            sourceLanguage: cycle.sourceLanguage,
            canRemove: cycle.modes.count > ModeCycleService.minSlots && activeIndex != 0,
            isLocked: cycle.isLocked(at: activeIndex),
            onChange: { mutate in cycle.update(id: activeMode.id, mutate: mutate) },
            onMove: { dir in cycle.move(id: activeMode.id, by: dir) },
            onRemove: { cycle.removeMode(id: activeMode.id) }
        )
    }
}

// MARK: - Sample-through-all

private extension ModesView {
    var sampleSection: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 0) {
                Text("One sentence,\n\(Text("every mode.").italic())")
                    .font(DS.Font.serif(22))
                    .tracking(-0.3)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 8)
                    .padding(.top, 12)

                Text("The same dictation routed through each slot on your reel.")
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
                    .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 6) {
                    MetaLabel(text: "You said")
                    Text("“\(ModesSample.input)”")
                        .font(DS.Font.serifItalic(13))
                        .lineSpacing(3)
                        .foregroundStyle(DS.Palette.ink2)
                }
                .padding(12)
                .background(DS.Palette.paper2, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Palette.ruleSoft, lineWidth: 1))
            }
            .frame(width: 200, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(cycle.modes.enumerated()), id: \.element.id) { idx, mode in
                    SampleRow(
                        mode: mode,
                        index: idx,
                        isFirst: idx == 0,
                        isActive: mode.id == activeMode.id,
                        sourceLanguage: cycle.sourceLanguage
                    ) {
                        activeID = mode.id
                        cycle.setStep(idx)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
            .dsPanel()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - ModeSlotCard

private struct ModeSlotCard: View {
    let mode: Mode
    let index: Int
    let isActive: Bool
    let sourceLanguage: AppLanguage
    let onTap: () -> Void

    private var num: String { String(format: "%02d", index + 1) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(num)
                        .font(DS.Font.mono(10))
                        .tracking(1.0)
                        .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    Spacer()
                    Text(mode.type.label.uppercased())
                        .font(DS.Font.mono(8))
                        .tracking(1.2)
                        .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                }
                .padding(.bottom, 14)

                glyph
                    .frame(height: 48)
                    .padding(.bottom, 14)

                Text(mode.title(source: sourceLanguage))
                    .font(DS.Font.sans(14, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)

                Text(subtitleText)
                    .font(DS.Font.mono(9))
                    .tracking(0.6)
                    .padding(.top, 4)
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(width: 168, height: 168, alignment: .topLeading)
            .background(isActive ? DS.Palette.ink : DS.Palette.paper,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glyph: some View {
        if let emoji = mode.displayEmoji {
            Text(emoji)
                .font(.system(size: 34))
        } else {
            Image(systemName: mode.type.systemImage)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
        }
    }

    private var subtitleText: String {
        if mode.type == .translate {
            let target = LanguageCatalog.language(for: mode.targetCode ?? "en")
            return "\(sourceLanguage.code.uppercased()) → \(target.code.uppercased())"
        }
        return mode.subtitleText
    }
}

// MARK: - AddSlotButton

private struct AddSlotButton: View {
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .regular))
                Text(disabled ? "FULL" : "ADD")
                    .font(DS.Font.mono(8))
                    .tracking(1.2)
            }
            .frame(width: 72, height: 168)
            .foregroundStyle(disabled ? DS.Palette.ink3 : DS.Palette.ink2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        disabled ? DS.Palette.ink.opacity(0.10) : DS.Palette.ink.opacity(0.22),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - ActiveModeCard

private struct ActiveModeCard: View {
    let mode: Mode
    let index: Int
    let total: Int
    let sourceLanguage: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                MetaLabel(text: "Now landing", color: DS.Palette.paper.opacity(0.6))
                Spacer()
                Text("SLOT \(String(format: "%02d", index + 1)) / \(String(format: "%02d", total))")
                    .font(DS.Font.mono(9))
                    .tracking(1.0)
                    .foregroundStyle(DS.Palette.paper.opacity(0.55))
            }
            .padding(.bottom, 16)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)

                    if let emoji = mode.displayEmoji {
                        Text(emoji).font(.system(size: 30))
                    } else {
                        Image(systemName: mode.type.systemImage)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(DS.Palette.paper)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title(source: sourceLanguage))
                        .font(DS.Font.serif(26))
                        .tracking(-0.3)
                        .foregroundStyle(DS.Palette.paper)
                    MetaLabel(text: mode.type.label, color: DS.Palette.paper.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            SoftDivider()
                .opacity(0.4)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 8) {
                MetaLabel(text: "Sample output", color: DS.Palette.paper.opacity(0.45))
                Text(ModesSample.output(for: mode))
                    .font(DS.Font.serifItalic(14))
                    .lineSpacing(3)
                    .lineLimit(6)
                    .foregroundStyle(DS.Palette.paper.opacity(0.92))
            }
        }
        .padding(26)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
    }
}

// MARK: - SlotEditor

private struct SlotEditor: View {
    let mode: Mode
    let index: Int
    let total: Int
    let sourceLanguage: AppLanguage
    let canRemove: Bool
    let isLocked: Bool
    let onChange: ((inout Mode) -> Void) -> Void
    let onMove: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            HStack(alignment: .top, spacing: 0) {
                typeRail
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .frame(width: 220, alignment: .topLeading)

                Rectangle()
                    .fill(DS.Palette.ruleSoft)
                    .frame(width: 1)

                paramsPane
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.panel).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.panel))
    }

    // Header
    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                MetaLabel(text: "Editing slot \(String(format: "%02d", index + 1))",
                          color: DS.Palette.accent)
                Text("·")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                Text(mode.title(source: sourceLanguage))
                    .font(DS.Font.serif(18))
                    .tracking(-0.2)
                    .foregroundStyle(DS.Palette.ink)
                if isLocked {
                    Text("LOCKED")
                        .font(DS.Font.mono(8))
                        .tracking(1.2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Palette.ink.opacity(0.06), in: Capsule())
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                EditorIconButton(icon: "arrow.left", disabled: isLocked || index <= 1) { onMove(-1) }
                EditorIconButton(icon: "arrow.right", disabled: isLocked || index == total - 1) { onMove(1) }
                EditorIconButton(icon: "trash", disabled: !canRemove, danger: true) { onRemove() }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(DS.Palette.paper2)
        .overlay(
            Rectangle()
                .fill(DS.Palette.ruleSoft)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
    }

    // Type rail
    @ViewBuilder
    private var typeRail: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetaLabel(text: "Mode type")
                .padding(.bottom, 8)
            if isLocked {
                LockedRawNotice()
            } else {
                ForEach(ModeType.allCases, id: \.self) { type in
                    TypeRailRow(type: type, isOn: mode.type == type) {
                        onChange { slot in
                            slot.type = type
                            applyDefaults(to: &slot, for: type)
                        }
                    }
                }
            }
        }
    }

    private func applyDefaults(to slot: inout Mode, for type: ModeType) {
        switch type {
        case .translate:
            if (slot.targetCode ?? "") == "" {
                slot.targetCode = LanguageCatalog.all.first(where: { $0.code != sourceLanguage.code })?.code ?? "en"
            } else if slot.targetCode == sourceLanguage.code {
                slot.targetCode = LanguageCatalog.all.first(where: { $0.code != sourceLanguage.code })?.code ?? "en"
            }
        case .custom:
            if (slot.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty { slot.name = "New mode" }
            if (slot.emoji ?? "").trimmingCharacters(in: .whitespaces).isEmpty { slot.emoji = "✨" }
            if (slot.prompt ?? "").isEmpty { slot.prompt = "Rewrite the transcription as …" }
        case .raw, .developer, .email, .snippets:
            break
        }
    }

    // Params pane
    @ViewBuilder
    private var paramsPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "About this type")
                .padding(.bottom, 10)
            Text(mode.type.blurb)
                .font(DS.Font.serifItalic(15))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 22)

            paramsForCurrentType
        }
    }

    @ViewBuilder
    private var paramsForCurrentType: some View {
        switch mode.type {
        case .raw:
            EmptyParams(
                title: "Nothing to configure.",
                body: "Whatever the speech engine returns gets pasted exactly as-is — punctuation, casing and all."
            )

        case .translate:
            translateParams

        case .developer:
            EmptyParams(
                title: "Tuned for engineers.",
                body: "Voicy condenses to terse, well-punctuated English. Backticks for `identifiers`, present-tense commit voice. Strips filler words."
            )

        case .email:
            EmptyParams(
                title: "Polite and structured.",
                body: "Adds a greeting matched to context, splits long thoughts into paragraphs, closes with a sign-off."
            )

        case .snippets:
            EmptyParams(
                title: "Manage snippets in the Snippets section.",
                body: "When this mode is active, Voicy scans your transcription for every snippet trigger you've defined and pastes the replacement text in their place. No AI involved."
            )

        case .custom:
            customParams
        }
    }

    private var translateParams: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    MetaLabel(text: "From")
                    Text("SET IN SETTINGS")
                        .font(DS.Font.mono(8))
                        .tracking(1.2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Palette.ink.opacity(0.06), in: Capsule())
                        .foregroundStyle(DS.Palette.ink3)
                }
                HStack(spacing: 12) {
                    Text(sourceLanguage.flag).font(.system(size: 18))
                    Text(sourceLanguage.native)
                        .font(DS.Font.sans(14, weight: .medium))
                        .foregroundStyle(DS.Palette.ink2)
                    Spacer()
                    Image(systemName: "lock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Palette.ink3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(DS.Palette.ink.opacity(0.18),
                                      style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Palette.ink3)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 6) {
                MetaLabel(text: "To")
                LangPicker(
                    value: mode.targetCode ?? "en",
                    excludeCode: sourceLanguage.code,
                    onPick: { code in
                        onChange { $0.targetCode = code }
                    }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var customParams: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    MetaLabel(text: "Icon")
                    EmojiInput(value: mode.emoji ?? "") { v in
                        onChange { $0.emoji = String(v.prefix(2)) }
                    }
                }
                .frame(width: 88)

                VStack(alignment: .leading, spacing: 6) {
                    MetaLabel(text: "Name")
                    TextField("e.g. Slack reply, Standup note",
                              text: Binding(
                                get: { mode.name ?? "" },
                                set: { v in onChange { $0.name = v } }
                              ))
                        .textFieldStyle(.plain)
                        .font(DS.Font.sans(14))
                        .foregroundStyle(DS.Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                MetaLabel(text: "System prompt")
                TextEditor(text: Binding(
                    get: { mode.prompt ?? "" },
                    set: { v in onChange { $0.prompt = v } }
                ))
                .scrollContentBackground(.hidden)
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink)
                .lineSpacing(3)
                .frame(minHeight: 96)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))

                Text("Voicy prepends the system prompt with the raw transcription. Reference it as ")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                +
                Text("{{transcript}}").font(DS.Font.mono(10)).foregroundColor(DS.Palette.accent)
                +
                Text(" to splice it explicitly.").font(DS.Font.mono(10)).foregroundColor(DS.Palette.ink3)
            }
        }
    }
}

// MARK: - Editor primitives

private struct LockedRawNotice: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: ModeType.raw.systemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Palette.ink2)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Raw")
                    .font(DS.Font.sans(13, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
                Text("Always slot 01. Cannot be changed.")
                    .font(DS.Font.mono(9))
                    .tracking(0.4)
                    .foregroundStyle(DS.Palette.ink3)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }
}

private struct TypeRailRow: View {
    let type: ModeType
    let isOn: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isOn ? DS.Palette.paper : DS.Palette.ink2)
                    .frame(width: 22, height: 22, alignment: .center)
                Text(type.label)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(isOn ? DS.Palette.paper : DS.Palette.ink2)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isOn ? DS.Palette.ink :
                (isHovering ? DS.Palette.ink.opacity(0.05) : .clear),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? DS.Palette.ink : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct EditorIconButton: View {
    let icon: String
    let disabled: Bool
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundStyle(disabled ? DS.Palette.ink3 : (danger ? DS.Palette.accent : DS.Palette.ink2))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private struct EmptyParams: View {
    let title: String
    let bodyText: String

    init(title: String, body: String) {
        self.title = title
        self.bodyText = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Font.serif(17))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink)
            Text(bodyText)
                .font(DS.Font.sans(13))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Palette.paper2, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}

private struct LangPicker: View {
    let value: String
    let excludeCode: String
    let onPick: (String) -> Void

    @State private var open = false

    private var lang: AppLanguage { LanguageCatalog.language(for: value) }

    var body: some View {
        Button(action: { open.toggle() }) {
            HStack(spacing: 12) {
                Text(lang.flag).font(.system(size: 18))
                Text(lang.native)
                    .font(DS.Font.sans(14, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .top) {
            LanguageGrid(excludeCode: excludeCode, selected: value) { code in
                onPick(code)
                open = false
            }
        }
    }
}

private struct LanguageGrid: View {
    let excludeCode: String
    let selected: String
    let onPick: (String) -> Void

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(LanguageCatalog.all) { lang in
                Button(action: { if lang.code != excludeCode { onPick(lang.code) } }) {
                    HStack(spacing: 10) {
                        Text(lang.flag).font(.system(size: 18))
                        Text(lang.native)
                            .font(DS.Font.sans(13, weight: .medium))
                            .foregroundStyle(lang.code == selected ? DS.Palette.paper : DS.Palette.ink)
                        Spacer(minLength: 0)
                        Text(lang.code.uppercased())
                            .font(DS.Font.mono(9))
                            .tracking(0.6)
                            .foregroundStyle(lang.code == selected ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minWidth: 180, alignment: .leading)
                    .background(
                        lang.code == selected ? DS.Palette.ink : .clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
                .disabled(lang.code == excludeCode)
                .opacity(lang.code == excludeCode ? 0.35 : 1)
            }
        }
        .padding(8)
        .frame(width: 380)
    }
}

private struct EmojiInput: View {
    let value: String
    let onChange: (String) -> Void

    var body: some View {
        TextField("", text: Binding(get: { value }, set: { v in onChange(String(v.prefix(2))) }))
            .textFieldStyle(.plain)
            .font(.system(size: 22))
            .foregroundStyle(DS.Palette.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}

// MARK: - SampleRow

private struct SampleRow: View {
    let mode: Mode
    let index: Int
    let isFirst: Bool
    let isActive: Bool
    let sourceLanguage: AppLanguage
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if !isFirst {
                    SoftDivider()
                }
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(DS.Font.mono(11, weight: .medium))
                                .tracking(0.6)
                                .foregroundStyle(isActive ? DS.Palette.accent : DS.Palette.ink3)
                            glyphChip
                        }
                        Text(mode.title(source: sourceLanguage))
                            .font(DS.Font.sans(13, weight: .semibold))
                            .foregroundStyle(DS.Palette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(mode.type.label.uppercased())
                            .font(DS.Font.mono(8))
                            .tracking(1.2)
                            .foregroundStyle(DS.Palette.ink3)
                    }
                    .frame(width: 140, alignment: .leading)

                    Text(ModesSample.output(for: mode))
                        .font(DS.Font.sans(15))
                        .lineSpacing(3)
                        .foregroundStyle(isActive ? DS.Palette.ink : DS.Palette.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glyphChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? DS.Palette.ink : DS.Palette.paper)
            RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1)
            if let emoji = mode.displayEmoji {
                Text(emoji).font(.system(size: 16))
            } else {
                Image(systemName: mode.type.systemImage)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
            }
        }
        .frame(width: 28, height: 28)
    }
}

