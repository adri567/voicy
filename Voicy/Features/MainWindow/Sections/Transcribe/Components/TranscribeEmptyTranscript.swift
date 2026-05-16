import SwiftUI

struct TranscribeEmptyTranscript: View {
    let stage: TranscribeStage

    var body: some View {
        VStack(spacing: 12) {
            Text(headline)
                .font(DS.Font.serifItalic(22))
                .tracking(-0.2)
                .foregroundStyle(DS.Palette.ink3)

            Text(body_)
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink3)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
    }

    private var headline: String {
        switch stage {
        case .processing: "Listening…"
        case .idle:       "No transcript yet."
        case .done:       ""
        }
    }

    private var body_: String {
        switch stage {
        case .processing:
            "Voicy is decoding your file. The transcript will appear here once it finishes — usually a quarter of the recording length."
        case .idle:
            "Drop a file above, choose a source language, and the words will land here."
        case .done:
            ""
        }
    }
}
