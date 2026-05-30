import SwiftUI

struct TranscribeMasthead: View {
    let selectedEngine: TranscriptionEngine
    let availableEngines: [TranscriptionEngine]
    let onSelectEngine: (TranscriptionEngine) -> Void
    let engineLabel: (TranscriptionEngine) -> String
    let engineSubtitle: String
    let weeklyHoursLabel: String
    let weeklySessionsLabel: String

    var body: some View {
        HStack(alignment: .top, spacing: 56) {
            hero
                .frame(maxWidth: .infinity, alignment: .leading)

            TranscribeEngineStatCard(
                selectedEngine: selectedEngine,
                availableEngines: availableEngines,
                onSelectEngine: onSelectEngine,
                engineLabel: engineLabel,
                engineSubtitle: engineSubtitle,
                weeklyHoursLabel: weeklyHoursLabel,
                weeklySessionsLabel: weeklySessionsLabel
            )
            .frame(width: 360, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("◆")
                    .font(DS.Font.mono(9))
                    .foregroundStyle(DS.Palette.accent)
                MetaLabel(text: "The Studio", color: DS.Palette.accent)
                    .font(DS.Font.mono(9))
                Text("Beta")
                    .dsTag()
                    .padding(.leading, 6)
            }
            .padding(.bottom, 14)

            heroHeadline
                .padding(.bottom, 18)

            Text(subhead)
                .font(DS.Font.sans(16))
                .foregroundStyle(DS.Palette.ink2)
                .lineSpacing(5)
                .frame(maxWidth: 460, alignment: .leading)
        }
    }

    private var subhead: String {
        "Pull any audio or video file into Voicy — interviews, voice memos, board calls — and let it set them in type. Pick the engine and source language yourself, independent from your dictation setup."
    }

    @ViewBuilder
    private var heroHeadline: some View {
        let intro  = Text("Drop a recording.\nGet every ")
        let accent = Text("word.")
            .font(DS.Font.serifItalic(54))
            .foregroundStyle(DS.Palette.accent)
        Text("\(intro)\(accent)")
            .font(DS.Font.serif(54))
            .tracking(-0.8)
            .foregroundStyle(DS.Palette.ink)
            .lineSpacing(-6)
    }
}
