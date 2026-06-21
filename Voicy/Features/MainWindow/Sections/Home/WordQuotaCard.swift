import SwiftUI

/// Free-tier word-allowance card for the Home tab: a labelled progress bar over
/// the rolling 7-day window, with a tap that surfaces the upgrade prompt. Shown
/// only when the user is on Free (the owner passes a non-nil `WordQuota`).
struct WordQuotaCard: View {
    let quota: WordQuota
    let onUpgrade: () -> Void

    private var barColor: Color {
        if quota.isExhausted { return DS.Palette.accent }
        if quota.isNearLimit { return DS.Palette.highlight }
        return DS.Palette.ink
    }

    private var caption: String {
        if quota.isExhausted {
            return "You've used your free words for now. Upgrade to Pro for unlimited dictation."
        }
        return "Resets continuously — this counts the last 7 days. \(quota.remaining.formatted()) left."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            bar
            Text(caption)
                .font(DS.Font.sans(12))
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .dsPanel()
        .contentShape(Rectangle())
        .onTapGesture { onUpgrade() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Free word allowance: \(quota.used) of \(quota.limit) words used in the last 7 days")
        .accessibilityHint("Activates to upgrade to Pro")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                MetaLabel(text: "◆ Free plan", color: DS.Palette.accent)
                Text("Words this week")
                    .font(DS.Font.sans(14, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
            }
            Spacer()
            Text("\(quota.used.formatted()) / \(quota.limit.formatted())")
                .font(DS.Font.mono(12))
                .foregroundStyle(quota.isExhausted ? DS.Palette.accent : DS.Palette.ink2)
        }
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 8)
                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width * quota.fraction, height: 8)
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.3), value: quota.fraction)
    }
}
