import SwiftUI

struct MicrophoneSelectorView: View {

    @State private var viewModel = MicrophoneSelectorViewModel()

    var body: some View {
        Button(action: { viewModel.isOpen.toggle() }) {
            pillContent
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $viewModel.isOpen, arrowEdge: .top) {
            MicrophoneSelectorPopover(viewModel: viewModel)
        }
        .onAppear { viewModel.start() }
    }

    // MARK: - Pill content

    private var pillContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.Palette.accent)

            Text(displayName)
                .font(DS.Font.sans(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 170, alignment: .leading)

            Image(systemName: viewModel.isOpen ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(DS.Palette.ink3)
        }
    }

    private var displayName: String {
        viewModel.current?.name ?? "System default"
    }
}
