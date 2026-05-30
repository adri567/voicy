import SwiftUI

struct TranscribeEngineSelector: View {
    let selected: TranscriptionEngine
    let available: [TranscriptionEngine]
    let label: (TranscriptionEngine) -> String
    let onSelect: (TranscriptionEngine) -> Void

    @State private var showOptions = false

    var body: some View {
        if available.isEmpty {
            emptyState
        } else {
            triggerButton
        }
    }

    private var triggerButton: some View {
        Button {
            showOptions = true
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Text(label(selected))
                    .font(DS.Font.serif(28))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 6)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
            optionsList
        }
    }

    private var optionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(available, id: \.self) { engine in
                optionRow(for: engine)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 200)
        .background(DS.Palette.paper)
    }

    private func optionRow(for engine: TranscriptionEngine) -> some View {
        Button {
            onSelect(engine)
            showOptions = false
        } label: {
            HStack(spacing: 10) {
                Text(label(engine))
                    .font(DS.Font.sans(13, weight: engine == selected ? .semibold : .regular))
                    .foregroundStyle(DS.Palette.ink)
                Spacer(minLength: 8)
                if engine == selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var emptyState: some View {
        Text("No engine installed — open Engine section")
            .font(DS.Font.sans(13, weight: .medium))
            .foregroundStyle(DS.Palette.ink3)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
    }
}
