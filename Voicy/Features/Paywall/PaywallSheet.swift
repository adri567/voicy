import SwiftUI

/// Reusable upgrade prompt shown whenever a Free-tier limit is hit. The
/// `context` tailors the headline/body to the specific limit; the body lists
/// the full Pro benefit set so the value is clear regardless of entry point.
///
/// `onUpgrade` is where the purchase flow will hook in (Lemon Squeezy). Today
/// it's wired by the caller — until that lands, the primary action simply
/// surfaces the intent. The sheet never grants Pro itself.
struct PaywallSheet: View {
    let context: UpgradeContext
    let onUpgrade: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            benefits
                .padding(24)
            Divider()
            footer
        }
        .frame(width: 460)
        .background(DS.Palette.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            MetaLabel(text: "◆ Voicy Pro", color: DS.Palette.accent)
            Text(context.title)
                .font(DS.Font.serif(28))
                .tracking(-0.5)
                .foregroundStyle(DS.Palette.ink)
            Text(context.message)
                .font(DS.Font.sans(14))
                .lineSpacing(3)
                .foregroundStyle(DS.Palette.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetaLabel(text: "Everything in Pro")
            benefitRow("Unlimited dictation — no weekly word cap")
            benefitRow("Unlimited file transcription")
            benefitRow("Every AI model, including the largest")
            benefitRow("Up to \(PlanLimits.proModeSlots) mode slots + custom prompts")
            benefitRow("Unlimited snippets")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.Palette.accent)
            Text(text)
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink)
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Maybe later") { dismiss() }
                .buttonStyle(.plain)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
                .keyboardShortcut(.cancelAction)

            Spacer()

            Button {
                onUpgrade()
                dismiss()
            } label: {
                Text("Get Voicy Pro")
                    .font(DS.Font.sans(12, weight: .semibold))
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(DS.Palette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }
}
