import SwiftUI

struct TranscribeEngineStatCard: View {
    let selectedEngine: TranscriptionEngine
    let availableEngines: [TranscriptionEngine]
    let onSelectEngine: (TranscriptionEngine) -> Void
    let engineSubtitle: String
    let weeklyHoursLabel: String
    let weeklySessionsLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Engine for this page")
                .font(DS.Font.mono(9))
                .padding(.bottom, 12)

            TranscribeEngineSelector(
                selected: selectedEngine,
                available: availableEngines,
                onSelect: onSelectEngine
            )
            .padding(.bottom, 10)

            Text(engineSubtitle)
                .font(DS.Font.sans(12))
                .foregroundStyle(DS.Palette.ink3)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            SoftDivider()
                .padding(.vertical, 14)

            HStack(alignment: .top, spacing: 12) {
                TranscribeMiniStat(value: weeklyHoursLabel, label: "transcribed this week")
                TranscribeMiniStat(value: weeklySessionsLabel, label: "sessions captured")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .dsPanel()
    }
}
