import SwiftUI

struct TranscribeLangSelector: View {
    let label: String
    let hint: String
    let value: TranscribeLanguage
    let options: [TranscribeLanguage]
    let onChange: (TranscribeLanguage) -> Void
    var accent: Bool = false
    var disabled: Bool = false

    @State private var showOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                MetaLabel(text: label)
                    .font(DS.Font.mono(9))
                Spacer(minLength: 8)
                Text(hint)
                    .font(DS.Font.serifItalic(11))
                    .foregroundStyle(accent ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            triggerButton
        }
    }

    private var triggerButton: some View {
        Button {
            guard !disabled else { return }
            showOptions = true
        } label: {
            HStack(spacing: 10) {
                Text(value.flag)
                    .font(.system(size: 18))
                    .foregroundStyle(value.code == "auto" ? DS.Palette.accent : DS.Palette.ink)
                Text(value.native)
                    .font(DS.Font.sans(14, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .stroke(accent ? DS.Palette.accent : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
            optionsList
        }
    }

    private var optionsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(options) { option in
                    optionRow(for: option)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 220)
        .frame(maxHeight: 320)
        .background(DS.Palette.paper)
    }

    private func optionRow(for option: TranscribeLanguage) -> some View {
        Button {
            onChange(option)
            showOptions = false
        } label: {
            HStack(spacing: 10) {
                Text(option.flag)
                    .font(.system(size: 16))
                Text(option.native)
                    .font(DS.Font.sans(13, weight: option.code == value.code ? .semibold : .regular))
                    .foregroundStyle(DS.Palette.ink)
                Spacer(minLength: 8)
                if option.code == value.code {
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
}
