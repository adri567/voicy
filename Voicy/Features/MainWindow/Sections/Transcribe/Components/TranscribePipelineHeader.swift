import SwiftUI

struct TranscribePipelineHeader: View {
    let modeLabel: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            heading
            Spacer(minLength: 12)
            MetaLabel(text: modeLabel)
                .font(DS.Font.mono(9))
        }
    }

    @ViewBuilder
    private var heading: some View {
        let italic = { (text: String) in
            Text(text).font(DS.Font.serifItalic(26))
        }
        let from = Text("From ")
        let recording = italic("recording")
        let to = Text(" to ")
        let page = italic("page")
        Text("\(from)\(recording)\(to)\(page)")
            .font(DS.Font.serif(26))
            .tracking(-0.3)
            .foregroundStyle(DS.Palette.ink2)
    }
}
