import SwiftUI

struct TranscribeHistorySection: View {

    enum Filter: Hashable {
        case all
        case longForm
        case translated
    }

    let entries: [FileTranscriptionEntry]
    @Binding var filter: Filter
    let onOpen: (FileTranscriptionEntry) -> Void

    private var filtered: [FileTranscriptionEntry] {
        switch filter {
        case .all:        entries
        case .longForm:   entries.filter { $0.durationSeconds >= 300 }
        case .translated: []     // cosmetic — translation not implemented
        }
    }

    private var totalWords: Int {
        filtered.reduce(0) { $0 + $1.wordCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 20)

            if filtered.isEmpty {
                emptyState
            } else {
                list
            }

            footer
                .padding(.top, 18)
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            heading
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                TranscribeFilterChip(
                    label: "All",
                    isActive: filter == .all,
                    onTap: { filter = .all }
                )
                TranscribeFilterChip(
                    label: "Long form",
                    isActive: filter == .longForm,
                    onTap: { filter = .longForm }
                )
                TranscribeFilterChip(
                    label: "Translated",
                    isActive: filter == .translated,
                    disabled: true,
                    onTap: {}
                )
            }
        }
    }

    @ViewBuilder
    private var heading: some View {
        let prefix = Text("Earlier ")
        let italic = Text("transcripts").font(DS.Font.serifItalic(26))
        Text("\(prefix)\(italic)")
            .font(DS.Font.serif(26))
            .tracking(-0.3)
            .foregroundStyle(DS.Palette.ink2)
    }

    @ViewBuilder
    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filtered.enumerated(), id: \.element.id) { index, entry in
                TranscribeHistoryRow(
                    entry: entry,
                    isFirst: index == 0,
                    onOpen: { onOpen(entry) }
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 4)
        .dsPanel()
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(DS.Palette.ink3)
            Text("No earlier transcripts yet.")
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .dsPanel()
    }

    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            MetaLabel(text: "\(filtered.count) earlier transcripts · \(totalWords.formatted()) words on file")
                .font(DS.Font.mono(9))
            Spacer(minLength: 12)
            MetaLabel(text: "Originals stay on your Mac — never uploaded.")
                .font(DS.Font.mono(9))
        }
    }
}
