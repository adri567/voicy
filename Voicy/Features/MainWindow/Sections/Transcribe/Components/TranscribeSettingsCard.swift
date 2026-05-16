import SwiftUI

struct TranscribeSettingsCard: View {
    let source: TranscribeLanguage
    let sourceOptions: [TranscribeLanguage]
    let onSourceChange: (TranscribeLanguage) -> Void
    let showRerun: Bool
    let canRerun: Bool
    let onReRun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            languageBlock
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 18)

            Spacer(minLength: 0)

            if showRerun {
                rerunFooter
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .dsPanel()
    }

    @ViewBuilder
    private var languageBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            MetaLabel(text: "Step 02 — Language")
                .font(DS.Font.mono(9))
                .padding(.bottom, -10)

            TranscribeLangSelector(
                label: "Source",
                hint: "Language of the recording",
                value: source,
                options: sourceOptions,
                onChange: onSourceChange
            )
        }
    }

    @ViewBuilder
    private var rerunFooter: some View {
        VStack(spacing: 0) {
            SoftDivider()
            Button(action: onReRun) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Re-run with these settings")
                        .font(DS.Font.sans(13, weight: .semibold))
                }
                .foregroundStyle(DS.Palette.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(DS.Palette.ink, in: Capsule())
                .opacity(canRerun ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!canRerun)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(DS.Palette.paper2)
        }
    }
}
