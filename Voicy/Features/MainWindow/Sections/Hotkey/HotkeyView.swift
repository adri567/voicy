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
                    HotkeyModeCard(mode: m, isActive: mode == m, isImplemented: m == .hold) {
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
