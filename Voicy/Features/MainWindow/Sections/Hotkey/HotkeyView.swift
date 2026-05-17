import SwiftUI

struct HotkeyView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.vertical, 40)

                gesturesSection
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

                Text("One key,\n\(Text("three").italic().foregroundColor(DS.Palette.accent)) gestures.")
                    .font(DS.Font.serif(50))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 22)

                Text("Voicy lives on a single key — Fn. Hold it to dictate, double-tap it for hands-free mode, and use the arrow keys mid-recording to switch modes. No setup, no conflicts, no learning curve.")
                    .font(DS.Font.sans(15))
                    .lineSpacing(5)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 480, alignment: .leading)
                    .padding(.bottom, 28)

                tryItNow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            KeyboardVisualization()
                .frame(width: 360)
        }
    }

    private var tryItNow: some View {
        VStack(alignment: .leading, spacing: 10) {
            MetaLabel(text: "Try it now")
            HStack(spacing: 12) {
                kbd(label: "fn", highlight: true)
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

    private var gesturesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The \(Text("gestures").italic().foregroundColor(DS.Palette.ink))")
                .font(DS.Font.serif(26))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 20)

            HStack(alignment: .top, spacing: 14) {
                HotkeyGestureCard(
                    title: "Hold",
                    description: "Press and hold Fn. Speak. Release to insert the transcript into the focused field.",
                    gesture: "press · speak · release",
                    kicker: "The classic"
                )
                HotkeyGestureCard(
                    title: "Double-tap",
                    description: "Tap Fn twice quickly. The bubble stays open while you keep speaking. Tap Fn once more to stop.",
                    gesture: "tap·tap · speak · tap",
                    kicker: "Hands-free"
                )
                HotkeyGestureCard(
                    title: "Switch modes",
                    description: "While recording, hold Fn and tap the arrow keys to cycle through your modes without letting go.",
                    gesture: "fn + ◀ / ▶",
                    kicker: "On the fly"
                )
            }
        }
    }

    private func kbd(label: String, highlight: Bool) -> some View {
        Text(label)
            .font(DS.Font.mono(13, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
            .frame(minWidth: 56, minHeight: 28)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.kbd)
                    .fill(highlight ? DS.Palette.highlight : DS.Palette.paperCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.kbd)
                    .stroke(Color.black.opacity(0.18), lineWidth: 1)
            )
    }
}
