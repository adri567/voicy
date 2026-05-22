import SwiftUI

struct SlotEditor: View {
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
                EditorIconButton(icon: "arrow.left", label: "Move mode left", disabled: isLocked || index <= 1) { onMove(-1) }
                EditorIconButton(icon: "arrow.right", label: "Move mode right", disabled: isLocked || index == total - 1) { onMove(1) }
                EditorIconButton(icon: "trash", label: "Remove mode", disabled: !canRemove, danger: true) { onRemove() }
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

                let prefix = Text("Voicy prepends the system prompt with the raw transcription. Reference it as ")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                let token = Text("{{transcript}}")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.accent)
                let suffix = Text(" to splice it explicitly.")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                Text("\(prefix)\(token)\(suffix)")
            }
        }
    }
}
