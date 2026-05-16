import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TranscribeDropZone: View {
    let onUpload: (URL) -> Void
    @State private var isHovering = false

    private let formats = ["m4a", "mp3", "wav", "aac", "flac", "mp4", "mov", "m4v"]

    var body: some View {
        Button(action: handleClick) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 28)
                footer
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
            .background(backgroundFill, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            )
        }
        .buttonStyle(.plain)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onUpload(url)
            return true
        } isTargeted: { hovering in
            isHovering = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetaLabel(text: "Step 01 — Drop in")
                .font(DS.Font.mono(9))

            headline
                .frame(maxWidth: 420, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var headline: some View {
        let lead = Text("Drag an audio or video file here, or ")
        let accent = Text("click to browse.")
            .font(DS.Font.serifItalic(32))
            .foregroundStyle(DS.Palette.accent)
        Text("\(lead)\(accent)")
            .font(DS.Font.serif(32))
            .tracking(-0.3)
            .foregroundStyle(DS.Palette.ink)
            .lineSpacing(2)
    }

    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                MetaLabel(text: "Accepts")
                    .font(DS.Font.mono(8))
                HStack(spacing: 6) {
                    ForEach(formats, id: \.self) { ext in
                        Text(".\(ext)")
                            .font(DS.Font.mono(9))
                            .dsTag()
                    }
                }
            }
            Spacer(minLength: 12)
            uploadButton
        }
    }

    private var uploadButton: some View {
        ZStack {
            Circle()
                .fill(DS.Palette.ink)
                .frame(width: 56, height: 56)
                .shadow(color: DS.Palette.ink.opacity(0.45), radius: 9, x: 0, y: 8)
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DS.Palette.paper)
        }
    }

    private var backgroundFill: Color {
        isHovering ? DS.Palette.accent.opacity(0.04) : DS.Palette.paperCard
    }

    private var borderColor: Color {
        isHovering ? DS.Palette.accent : DS.Palette.ink.opacity(0.22)
    }

    private func handleClick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            onUpload(url)
        }
    }
}
