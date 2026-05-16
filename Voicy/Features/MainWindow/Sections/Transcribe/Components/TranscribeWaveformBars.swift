import SwiftUI

struct TranscribeWaveformBars: View {

    enum Style {
        case live(progress: Double)
        case player(playhead: Double)
    }

    let style: Style
    var height: CGFloat = 60

    var body: some View {
        let bars = TranscribeProceduralWaveform.bars
        let total = bars.count

        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                let fraction = Double(i) / Double(total)
                let normalized = bars[i]
                let passed: Bool = {
                    switch style {
                    case .live(let progress):   fraction < progress
                    case .player(let playhead): fraction < playhead
                    }
                }()
                let animated: Bool = {
                    if case .live = style { return true } else { return false }
                }()

                TranscribeWaveformBar(
                    passed: passed,
                    animated: animated,
                    height: max(2, normalized * height),
                    index: i
                )
                .frame(width: 4)
            }
        }
        .frame(height: height)
    }
}
