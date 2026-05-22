import SwiftUI

struct SnippetRow: View {
    let snippet: SnippetDTO
    let index: Int
    let first: Bool
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                Text(String(format: "%02d", index))
                    .font(DS.Font.serifItalic(36))
                    .foregroundStyle(snippet.enabled ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    triggerChips
                    Text(snippet.replacement)
                        .font(DS.Font.sans(14))
                        .lineSpacing(3)
                        .foregroundStyle(DS.Palette.ink)
                        .frame(maxWidth: 580, alignment: .leading)
                        .opacity(snippet.enabled ? 1.0 : 0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actionBlock
                    .frame(width: 160, alignment: .trailing)
            }
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
    }

    private var triggerChips: some View {
        HStack(spacing: 6) {
            ForEach(snippet.triggers, id: \.self) { trigger in
                Text("„\(trigger)\"")
                    .font(DS.Font.serifItalic(15))
                    .foregroundStyle(DS.Palette.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.04), in: Capsule())
            }
        }
    }

    private var actionBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(snippet.enabled ? "Enabled" : "Disabled")
                .dsTag(solid: false, accent: snippet.enabled)

            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Image(systemName: snippet.enabled ? "pause" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.ink)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.ink, lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(snippet.enabled ? "Disable" : "Enable")
                .accessibilityLabel(snippet.enabled ? "Disable snippet" : "Enable snippet")

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.ink)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.ink, lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Edit")
                .accessibilityLabel("Edit snippet")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.accent)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.accent.opacity(0.5), lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Delete")
                .accessibilityLabel("Delete snippet")
            }
        }
    }
}
