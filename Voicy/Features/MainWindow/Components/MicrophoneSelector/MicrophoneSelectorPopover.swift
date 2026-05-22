import SwiftUI

struct MicrophoneSelectorPopover: View {

    @Bindable var viewModel: MicrophoneSelectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            list
            footer
        }
        .frame(width: 320)
        .background(DS.Palette.paper)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Input device")
                .font(DS.Font.mono(9, weight: .medium))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(DS.Palette.ink3)
            Spacer()
            Text("\(viewModel.devices.count) available")
                .font(DS.Font.serifItalic(12))
                .foregroundStyle(DS.Palette.ink3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(DS.Palette.paper2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.Palette.ruleSoft)
                .frame(height: 1)
        }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if viewModel.devices.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "mic.slash")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(DS.Palette.ink3)
                Text("No input devices found")
                    .font(DS.Font.sans(12))
                    .foregroundStyle(DS.Palette.ink3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.devices) { device in
                    MicrophoneRow(
                        device: device,
                        isActive: viewModel.selectedUID == device.uid
                    ) {
                        viewModel.select(device)
                    }
                }
            }
            .padding(6)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(action: { viewModel.selectSystemDefault() }) {
                Text(viewModel.isFollowingSystemDefault
                     ? "System default · follow Mac"
                     : "Use system default")
                    .font(DS.Font.mono(8, weight: .medium))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(viewModel.isFollowingSystemDefault
                                     ? DS.Palette.ink3
                                     : DS.Palette.ink2)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: viewModel.openSoundSettings) {
                Text("Sound settings ↗")
                    .font(DS.Font.mono(9, weight: .medium))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(DS.Palette.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(DS.Palette.paper2)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DS.Palette.ruleSoft)
                .frame(height: 1)
        }
    }
}
