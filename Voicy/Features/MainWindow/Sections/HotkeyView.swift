import SwiftUI

struct HotkeyView: View {

    // MOCK: only `.fn` is actually wired. The others change the UI state but
    // don't rebind the global monitor. TODO(hotkey-rebind).
    @State private var trigger: TriggerOption = .fn
    @State private var mode: HotkeyMode = .hold

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.vertical, 40)

                triggerPicker
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 40)

                modeSelector
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
    }

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ Essay", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("A single key,\n\(Text("summoned").italic().foregroundColor(DS.Palette.accent)) on instinct.")
                    .font(DS.Font.serif(50))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 22)

                Text("Your hotkey is the smallest, most important decision you'll make in Voicy. Pick a key your fingers can find in the dark; pick a key you don't already use for something else. Hold it. Speak. Let go.")
                    .font(DS.Font.sans(15))
                    .lineSpacing(5)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 480, alignment: .leading)
                    .padding(.bottom, 28)

                tryItNow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            KeyboardVisualization(active: trigger)
                .frame(width: 360)
        }
    }

    private var tryItNow: some View {
        VStack(alignment: .leading, spacing: 10) {
            MetaLabel(text: "Try it now")
            HStack(spacing: 12) {
                kbd(label: trigger.label, highlight: true)
                Text("+ hold to dictate")
                    .font(DS.Font.serifItalic(20))
                    .foregroundStyle(DS.Palette.ink2)
            }
        }
        .padding(20)
        .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DS.Palette.ruleSoft, lineWidth: 1)
        )
    }

    private var triggerPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose your \(Text("trigger").italic().foregroundColor(DS.Palette.ink))")
                .font(DS.Font.serif(26))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 20)

            VStack(spacing: 0) {
                ForEach(Array(TriggerOption.allCases.enumerated()), id: \.element.id) { idx, opt in
                    triggerRow(idx: idx, opt: opt)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
            .dsPanel()
        }
    }

    private func triggerRow(idx: Int, opt: TriggerOption) -> some View {
        let isActive = trigger == opt

        return VStack(spacing: 0) {
            if idx != 0 { SoftDivider() }
            HStack(alignment: .center, spacing: 24) {
                Text(String(format: "%02d", idx + 1))
                    .font(DS.Font.serifItalic(28))
                    .foregroundStyle(isActive ? DS.Palette.accent : DS.Palette.ink3)
                    .frame(width: 60, alignment: .leading)

                kbd(label: opt.label, highlight: false, active: isActive)
                    .frame(width: 80, alignment: .leading)

                Text(opt.description)
                    .font(DS.Font.sans(14))
                    .lineSpacing(2)
                    .foregroundStyle(isActive ? DS.Palette.ink2 : DS.Palette.ink3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(isActive ? DS.Palette.accent : DS.Palette.ink, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if isActive {
                        Circle()
                            .fill(DS.Palette.accent)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 30)
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
            .onTapGesture {
                trigger = opt
                // TODO(hotkey-rebind): re-register the global monitor with the new key.
            }
        }
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The \(Text("gesture").italic().foregroundColor(DS.Palette.ink))")
                .font(DS.Font.serif(26))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 8)

            Text("How does the key behave? Hold is forgiving; toggle is hands-free; double-tap is for the fast-fingered.")
                .font(DS.Font.sans(14))
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink2)
                .frame(maxWidth: 600, alignment: .leading)
                .padding(.bottom, 20)

            HStack(spacing: 14) {
                ForEach(HotkeyMode.allCases, id: \.self) { m in
                    ModeCard(mode: m, isActive: mode == m, isImplemented: m == .hold) {
                        mode = m
                        // TODO(hotkey-mode): toggle/double-tap require new gesture detection
                    }
                }
            }

            HStack {
                MetaLabel(text: "Your shortcut is saved on this Mac only.")
                Spacer()
                // MOCK: custom-shortcut recorder. TODO(hotkey-record).
                Button("Record a custom shortcut") {}
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(12, weight: .semibold))
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(DS.Palette.ink, in: Capsule())
            }
            .padding(.top, 40)
        }
    }

    private func kbd(label: String, highlight: Bool, active: Bool = false) -> some View {
        Text(label)
            .font(DS.Font.mono(13, weight: .medium))
            .foregroundStyle(active ? DS.Palette.paper : DS.Palette.ink)
            .frame(minWidth: 56, minHeight: 28)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.kbd)
                    .fill(highlight ? DS.Palette.highlight : (active ? DS.Palette.ink : DS.Palette.paperCard))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.kbd)
                    .stroke(active ? DS.Palette.ink : Color.black.opacity(0.18), lineWidth: 1)
            )
    }
}

private enum HotkeyMode: String, CaseIterable, Hashable {
    case hold, toggle, double

    var title: String {
        switch self {
        case .hold:   "Hold"
        case .toggle: "Toggle"
        case .double: "Double-tap"
        }
    }
    var subtitle: String {
        switch self {
        case .hold:   "Press & hold"
        case .toggle: "Tap to start, tap to stop"
        case .double: "Two quick taps"
        }
    }
    var description: String {
        switch self {
        case .hold:   "The classic. Speak while the key is down; release to send."
        case .toggle: "Hands-free. Tap once to start, tap again when done."
        case .double: "Doesn't conflict with anything. Double-tap to arm, then dictate."
        }
    }
    var gesture: String {
        switch self {
        case .hold:   "press · speak · release"
        case .toggle: "tap · speak · tap"
        case .double: "tap·tap · speak"
        }
    }
}

private enum TriggerOption: String, CaseIterable, Identifiable, Hashable {
    case fn, rcmd, ralt, caps, custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fn:     "fn"
        case .rcmd:   "⌘"
        case .ralt:   "⌥"
        case .caps:   "⇪"
        case .custom: "Custom…"
        }
    }
    var description: String {
        switch self {
        case .fn:     "The Function key. Empty by default. The current default."
        case .rcmd:   "The right Command key. Easy to find without looking."
        case .ralt:   "The right Option key. Stays out of the way."
        case .caps:   "Caps Lock — for those who never use it anyway."
        case .custom: "Choose any combination — like ⇧ + Space."
        }
    }
}

private struct ModeCard: View {
    let mode: HotkeyMode
    let isActive: Bool
    let isImplemented: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    MetaLabel(text: mode.subtitle, color: isActive ? DS.Palette.paper.opacity(0.55) : DS.Palette.ink3)
                    Spacer()
                    if !isImplemented {
                        // MOCK marker
                        Text("Soon")
                            .font(DS.Font.mono(8))
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                            .overlay(Capsule().stroke(isActive ? DS.Palette.paper.opacity(0.3) : DS.Palette.ruleSoft, lineWidth: 1))
                    }
                }
                .padding(.bottom, 12)

                Text(mode.title)
                    .font(DS.Font.serif(32))
                    .foregroundStyle(isActive ? DS.Palette.paper : DS.Palette.ink)
                    .padding(.bottom, 8)

                Text(mode.description)
                    .font(DS.Font.sans(13))
                    .lineSpacing(2)
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.75) : DS.Palette.ink2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)

                Text(mode.gesture)
                    .font(DS.Font.mono(10))
                    .foregroundStyle(isActive ? DS.Palette.paper.opacity(0.6) : DS.Palette.ink3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        isActive ? Color.white.opacity(0.06) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? Color.white.opacity(0.1) : DS.Palette.ruleSoft, lineWidth: 1)
                    )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .fill(isActive ? DS.Palette.ink : DS.Palette.paperCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(isActive ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .shadow(color: isActive ? .black.opacity(0.3) : .black.opacity(0.03), radius: isActive ? 24 : 2, y: isActive ? 12 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyboard visualization (dekorativ)

private struct KeyboardVisualization: View {
    let active: TriggerOption

    private let rows: [[String]] = [
        ["esc","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"],
        ["~","1","2","3","4","5","6","7","8","9","0","-","="],
        ["tab","Q","W","E","R","T","Y","U","I","O","P","[","]"],
        ["caps","A","S","D","F","G","H","J","K","L",";","'","↩"],
        ["⇧","Z","X","C","V","B","N","M",",",".","/","⇧"],
        ["fn","⌃","⌥","⌘","space","⌘","⌥","◀","▼","▶"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Magic Keyboard · live preview", color: DS.Palette.paper.opacity(0.45))
                .padding(.bottom, 16)

            VStack(spacing: 4) {
                ForEach(0..<rows.count, id: \.self) { ri in
                    HStack(spacing: 4) {
                        ForEach(0..<rows[ri].count, id: \.self) { ci in
                            keyCap(rows[ri][ci])
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack {
                Text("○ ready")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.paper.opacity(0.5))
                Spacer()
                MetaLabel(text: "conflicts: none detected", color: DS.Palette.paper.opacity(0.4))
            }
            .padding(.top, 18)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(red: 0.165, green: 0.149, blue: 0.122), Color(red: 0.102, green: 0.094, blue: 0.078)],
                startPoint: .top, endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
    }

    private func keyCap(_ label: String) -> some View {
        let isActive = isActiveKey(label)
        let width: CGFloat = label == "space" ? 80 : (label.count > 1 && label != "↩" ? 30 : 22)

        return ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? DS.Palette.accent : Color(red: 0.239, green: 0.220, blue: 0.188))
                .frame(height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: isActive ? DS.Palette.accent.opacity(0.5) : .clear, radius: 8)

            if label != "space" {
                Text(label)
                    .font(DS.Font.mono(label.count > 1 ? 8 : 10, weight: .medium))
                    .foregroundStyle(isActive ? DS.Palette.accentInk : DS.Palette.paper.opacity(0.6))
            }
        }
        .frame(width: width)
    }

    private func isActiveKey(_ label: String) -> Bool {
        switch active {
        case .fn:     return label == "fn"
        case .rcmd:   return label == "⌘"
        case .ralt:   return label == "⌥"
        case .caps:   return label == "caps"
        case .custom: return false
        }
    }
}
