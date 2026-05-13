import SwiftUI

// MARK: - Picker target

private enum PickerSlot: Equatable {
    case source
    case target(Int) // 0…2
}

// MARK: - LanguagesView

struct LanguagesView: View {

    @Bindable var cycle: LanguageCycleService

    @State private var pickerOpen: PickerSlot? = nil

    private var sourceLang: AppLanguage { cycle.source }
    private var activeLang: AppLanguage { cycle.activeLanguage }
    private var targets: [AppLanguage?] { cycle.targets }
    private var source: String { cycle.source.code }
    private var activeStep: Int { cycle.step }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)
                    .padding(.bottom, 36)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)

                flowSection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, 32)
                    .padding(.bottom, 36)

                howItSoundsSection
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
    }

    // MARK: Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ The Atelier", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("Speak one language.\nLand in \(Text("three more.").italic().foregroundColor(DS.Palette.accent))")
                    .font(DS.Font.serif(54))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                instructionParagraph
                    .frame(maxWidth: 560, alignment: .leading)
            }

            ActivePreview(
                source: sourceLang,
                active: activeLang,
                step: activeStep
            )
            .frame(maxWidth: 380)
        }
    }

    private var instructionParagraph: some View {
        // Inline keycaps via Text-Interpolation (macOS 26 friendly).
        let fnKbd = Text(" fn ")
            .font(DS.Font.mono(12, weight: .medium))
            .foregroundColor(DS.Palette.ink)
        let arrowKbd = Text(" → ")
            .font(DS.Font.mono(12, weight: .medium))
            .foregroundColor(DS.Palette.ink)

        return Text("You always speak in your default tongue. Voicy transcribes it verbatim. Tap \(arrowKbd) while holding \(fnKbd) to cycle through three translation targets — once for the first, twice for the second, three times for the third.")
            .font(DS.Font.sans(16))
            .lineSpacing(4)
            .foregroundStyle(DS.Palette.ink2)
    }

    // MARK: Flow

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .lastTextBaseline) {
                Text("Your \(Text("flow").italic().foregroundColor(DS.Palette.ink2))")
                    .font(DS.Font.serif(26))
                    .foregroundStyle(DS.Palette.ink2)

                Spacer()

                MetaLabel(text: "Hold fn · tap → to cycle", color: DS.Palette.ink3)
            }

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    LanguageSlot(
                        kind: .source,
                        lang: sourceLang,
                        caption: "You speak",
                        shortcut: "fn",
                        isActive: activeStep == 0
                    ) {
                        cycle.setStep(0)
                        pickerOpen = .source
                    }

                    Arrow(taps: 1)

                    LanguageSlot(
                        kind: .target,
                        lang: targets[0],
                        caption: "Target 1",
                        shortcut: "fn + →",
                        isActive: activeStep == 1
                    ) {
                        if targets[0] != nil { cycle.setStep(1) }
                        pickerOpen = .target(0)
                    }

                    Arrow(taps: 2)

                    LanguageSlot(
                        kind: .target,
                        lang: targets[1],
                        caption: "Target 2",
                        shortcut: "fn + → →",
                        isActive: activeStep == 2
                    ) {
                        if targets[1] != nil { cycle.setStep(2) }
                        pickerOpen = .target(1)
                    }

                    Arrow(taps: 3)

                    LanguageSlot(
                        kind: .target,
                        lang: targets[2],
                        caption: "Target 3",
                        shortcut: "fn + → → →",
                        isActive: activeStep == 3
                    ) {
                        if targets[2] != nil { cycle.setStep(3) }
                        pickerOpen = .target(2)
                    }
                }

                if let slot = pickerOpen {
                    pickerDrawer(for: slot)
                        .padding(.top, 22)
                }
            }
            .padding(28)
            .dsPanel()
        }
    }

    private func pickerDrawer(for slot: PickerSlot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SoftDivider()
                .padding(.bottom, 8)

            HStack(spacing: 8) {
                MetaLabel(text: pickerTitle(for: slot), color: DS.Palette.ink3)
                Spacer()
                if case .target(let i) = slot, targets[i] != nil {
                    Button(action: {
                        cycle.clearTarget(at: i)
                        pickerOpen = nil
                    }) {
                        Text("Clear")
                            .font(DS.Font.sans(11))
                            .foregroundStyle(DS.Palette.ink3)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Button(action: { pickerOpen = nil }) {
                    Text("Close")
                        .font(DS.Font.sans(11))
                        .foregroundStyle(DS.Palette.ink3)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            WrapHStack(spacing: 8, runSpacing: 8) {
                ForEach(LanguageCatalog.all) { lang in
                    pickerPill(lang: lang, slot: slot)
                }
            }
        }
    }

    private func pickerTitle(for slot: PickerSlot) -> String {
        switch slot {
        case .source:        return "Pick the language you speak"
        case .target(let i): return "Pick the target for slot \(i + 1)"
        }
    }

    @ViewBuilder
    private func pickerPill(lang: AppLanguage, slot: PickerSlot) -> some View {
        let targetCodes: [String?] = targets.map { $0?.code }
        let taken: Bool = {
            switch slot {
            case .source:
                return targetCodes.contains(lang.code)
            case .target(let i):
                let inOtherTarget = targetCodes.enumerated().contains { idx, code in
                    idx != i && code == lang.code
                }
                return lang.code == source || inOtherTarget
            }
        }()
        let selected: Bool = {
            switch slot {
            case .source:        return source == lang.code
            case .target(let i): return targetCodes[i] == lang.code
            }
        }()
        let disabled = taken && !selected

        Button(action: {
            if disabled { return }
            switch slot {
            case .source:        cycle.setSource(lang.code)
            case .target(let i): cycle.setTarget(at: i, code: lang.code)
            }
            pickerOpen = nil
        }) {
            HStack(spacing: 8) {
                Text(lang.flag)
                    .font(.system(size: 16))
                Text(lang.native)
                    .font(DS.Font.sans(13, weight: .medium))
                if disabled {
                    Text("· in use")
                        .font(DS.Font.mono(9))
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(pillTextColor(selected: selected, disabled: disabled))
            .background(pillBackground(selected: selected), in: Capsule())
            .overlay(Capsule().stroke(pillBorder(selected: selected), lineWidth: 1))
            .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func pillTextColor(selected: Bool, disabled: Bool) -> Color {
        if selected { return DS.Palette.paper }
        if disabled { return DS.Palette.ink3 }
        return DS.Palette.ink
    }
    private func pillBackground(selected: Bool) -> Color {
        selected ? DS.Palette.ink : DS.Palette.paper
    }
    private func pillBorder(selected: Bool) -> Color {
        selected ? DS.Palette.ink : DS.Palette.ruleSoft
    }

    // MARK: How it sounds

    private var howItSoundsSection: some View {
        HStack(alignment: .top, spacing: 40) {
            VStack(alignment: .leading, spacing: 6) {
                Text("How it \(Text("sounds").italic().foregroundColor(DS.Palette.ink))")
                    .font(DS.Font.serif(22))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink)

                Text("The same sentence dropped into your source and any active targets.")
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(width: 200, alignment: .leading)
            .padding(.top, 12)

            VStack(spacing: 0) {
                ForEach(Array(activeSlots.enumerated()), id: \.offset) { idx, slot in
                    PreviewRow(
                        lang: slot.lang,
                        shortcut: slot.shortcut,
                        sample: LanguageCatalog.samplePreviews[slot.lang.code] ?? "",
                        isSource: slot.isSource,
                        showDivider: idx > 0
                    )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
            .dsPanel()
        }
    }

    private struct PreviewSlot {
        let lang: AppLanguage
        let shortcut: String
        let isSource: Bool
    }

    private var activeSlots: [PreviewSlot] {
        var result: [PreviewSlot] = [
            PreviewSlot(lang: sourceLang, shortcut: "fn", isSource: true)
        ]
        for (idx, target) in targets.enumerated() {
            guard let target else { continue }
            let shortcut = "fn + " + String(repeating: "→", count: idx + 1)
            result.append(PreviewSlot(lang: target, shortcut: shortcut, isSource: false))
        }
        return result
    }
}

// MARK: - Language Slot

private struct LanguageSlot: View {
    enum Kind { case source, target }

    let kind: Kind
    let lang: AppLanguage?
    let caption: String
    let shortcut: String
    let isActive: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    private var isEmpty: Bool { lang == nil }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                Text(caption)
                    .font(DS.Font.mono(9))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(captionColor)
                    .padding(.bottom, 14)

                if let lang {
                    Text(lang.flag)
                        .font(.system(size: 36))
                        .padding(.bottom, 12)

                    Text(lang.native)
                        .font(DS.Font.sans(17, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
                        .padding(.bottom, 4)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(DS.Palette.ink3)
                        .frame(height: 44)
                        .padding(.bottom, 12)

                    Text("Empty")
                        .font(DS.Font.sans(17, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(DS.Palette.ink3)
                        .padding(.bottom, 4)
                }

                Text(shortcut)
                    .font(DS.Font.mono(10))
                    .foregroundStyle(shortcutColor)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var captionColor: Color {
        if isActive { return DS.Palette.paper.opacity(0.55) }
        if isEmpty { return DS.Palette.ink3 }
        return kind == .source ? DS.Palette.accent : DS.Palette.ink3
    }
    private var shortcutColor: Color {
        isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3
    }
    private var background: Color {
        if isActive { return DS.Palette.ink }
        if isEmpty { return DS.Palette.paperCard.opacity(0.5) }
        return kind == .source ? DS.Palette.paperCard : DS.Palette.paper
    }
    private var borderColor: Color {
        if isActive { return DS.Palette.ink }
        return isHovering ? DS.Palette.ink3.opacity(0.5) : DS.Palette.ruleSoft
    }
}

// MARK: - Arrow connector

private struct Arrow: View {
    let taps: Int
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DS.Palette.ink3)
            Text("×\(taps)")
                .font(DS.Font.mono(9))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(DS.Palette.ink3)
        }
        .frame(width: 28)
    }
}

// MARK: - Active Preview Card

private struct ActivePreview: View {
    let source: AppLanguage
    let active: AppLanguage
    let step: Int

    private var same: Bool { source.code == active.code }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Currently landing in")
                .font(DS.Font.mono(9))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            HStack(spacing: 14) {
                Text(source.flag)
                    .font(.system(size: 40))
                if !same {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DS.Palette.paper.opacity(0.55))
                    Text(active.flag)
                        .font(.system(size: 40))
                }
            }
            .padding(.bottom, 18)

            if same {
                Text("\(source.native) \(Text("· verbatim").italic().foregroundColor(DS.Palette.paper.opacity(0.5)))")
                    .font(DS.Font.serif(28))
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.bottom, 4)
            } else {
                Text("\(source.native) \(Text("→").italic()) \(active.native)")
                    .font(DS.Font.serif(28))
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.bottom, 4)
            }

            Text(same ? "No translation — your voice, your words" : "Translation · target \(step)")
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.paper.opacity(0.7))
                .padding(.bottom, 22)

            HStack(spacing: 8) {
                Text("Taps →")
                    .font(DS.Font.mono(9))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(DS.Palette.paper.opacity(0.45))
                    .frame(minWidth: 60, alignment: .leading)

                ForEach(0..<4, id: \.self) { s in
                    Circle()
                        .fill(s == step ? DS.Palette.accent : Color.white.opacity(0.12))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(s == step ? DS.Palette.accent : Color.white.opacity(0.18), lineWidth: 2)
                        )
                }

                Spacer(minLength: 8)

                Text("\(step) / 3")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.paper.opacity(0.55))
            }
        }
        .padding(26)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
    }
}

// MARK: - Preview Row

private struct PreviewRow: View {
    let lang: AppLanguage
    let shortcut: String
    let sample: String
    let isSource: Bool
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            if showDivider { SoftDivider() }

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    KbdRow(shortcut: shortcut)
                    HStack(spacing: 6) {
                        Text(lang.flag)
                            .font(.system(size: 14))
                        Text(lang.native)
                            .font(DS.Font.sans(11))
                            .foregroundStyle(DS.Palette.ink3)
                        if isSource {
                            Text("· source")
                                .font(DS.Font.mono(8))
                                .textCase(.uppercase)
                                .tracking(1.2)
                                .foregroundStyle(DS.Palette.accent)
                        }
                    }
                }
                .frame(width: 140, alignment: .leading)

                Text(sample)
                    .font(DS.Font.sans(15))
                    .lineSpacing(4)
                    .foregroundStyle(isSource ? DS.Palette.ink : DS.Palette.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 20)
        }
    }
}

private struct KbdRow: View {
    let shortcut: String

    private var tokens: [String] {
        shortcut.replacingOccurrences(of: " + ", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Text(token)
                    .font(DS.Font.mono(12, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.kbd)
                            .fill(DS.Palette.paperCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.kbd)
                            .stroke(Color.black.opacity(0.18), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Flow-layout helper for the picker pills

private struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let runSpacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        FlowLayout(spacing: spacing, runSpacing: runSpacing) {
            content()
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var runSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + runSpacing
                maxRowWidth = max(maxRowWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        maxRowWidth = max(maxRowWidth, rowWidth - spacing)
        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            _ = maxWidth
        }
    }
}
