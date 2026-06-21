import SwiftUI

struct AddSlotButton: View {
    /// Plan-locked: the Free allowance is reached but the reel could hold more on
    /// Pro. Shown as a tappable "PRO" lock that surfaces the paywall — not
    /// disabled, so the tap actually fires.
    var locked: Bool = false
    /// Genuinely full: at the absolute slot cap, where even Pro can't add more.
    /// Truly disabled.
    let disabled: Bool
    let action: () -> Void

    private var label: String {
        if locked { return "PRO" }
        return disabled ? "FULL" : "ADD"
    }

    private var icon: String { locked ? "lock.fill" : "plus" }

    private var tint: Color {
        if locked { return DS.Palette.accent }
        return disabled ? DS.Palette.ink3 : DS.Palette.ink2
    }

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: locked ? 15 : 18, weight: .regular))
                Text(label)
                    .font(DS.Font.mono(8))
                    .tracking(1.2)
            }
            .frame(width: 72, height: 168)
            .foregroundStyle(tint)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        locked ? DS.Palette.accent.opacity(0.4)
                               : (disabled ? DS.Palette.ink.opacity(0.10) : DS.Palette.ink.opacity(0.22)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(locked ? "Upgrade to Pro for more mode slots" : "")
    }
}
