import SwiftUI

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

    // MARK: - Reel

    private var reelSection: some View {
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

    // MARK: - Editor section

    private var editorSection: some View {
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

    // MARK: - Sample-through-all

    private var sampleSection: some View {
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
