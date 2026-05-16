import SwiftUI

struct TranscribeTranscriptHeader: View {
    let copied: Bool
    let onCopy: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            heading
            Spacer(minLength: 12)

            HStack(spacing: 8) {
                TranscribeActionButton(
                    title: copied ? "✓ Copied" : "Copy all",
                    flash: copied,
                    action: onCopy
                )
                TranscribeActionButton(title: "Download .txt", action: onDownload)
                TranscribeActionButton(
                    title: "Send to Notes",
                    disabled: true,
                    trailing: "Soon"
                )
            }
        }
    }

    @ViewBuilder
    private var heading: some View {
        let the = Text("The ")
        let transcript = Text("transcript").font(DS.Font.serifItalic(26))
        Text("\(the)\(transcript)")
            .font(DS.Font.serif(26))
            .tracking(-0.3)
            .foregroundStyle(DS.Palette.ink2)
    }
}
