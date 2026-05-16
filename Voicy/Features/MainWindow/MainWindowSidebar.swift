import SwiftUI

struct MainWindowSidebar: View {

    let mode: SidebarMode
    @Binding var selection: SidebarSection
    var viewModel: RecordingViewModel

    var body: some View {
        VStack(spacing: 0) {
            wordmark
                .padding(.horizontal, mode.isCompact ? 12 : 22)
                .padding(.top, 14)
                .padding(.bottom, 26)

            nav
                .padding(.horizontal, mode.isCompact ? 8 : 12)

            Spacer(minLength: 0)

            statusFooter
                .padding(.horizontal, mode.isCompact ? 12 : 18)
                .padding(.bottom, 18)
                .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Palette.paper2)
    }

    @ViewBuilder
    private var wordmark: some View {
        if mode.isCompact {
            HStack {
                Spacer()
                Image("VoicyLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(DS.Palette.ink)
                Spacer()
            }
        } else {
            HStack(spacing: 12) {
                Image("VoicyLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(DS.Palette.ink)

                Text("Voicy")
                    .font(DS.Font.sans(22, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(DS.Palette.ink)

                Spacer()
            }
        }
    }

    private var nav: some View {
        VStack(spacing: 2) {
            ForEach(SidebarSection.allCases) { section in
                NavItem(
                    section: section,
                    isActive: selection == section,
                    isCompact: mode.isCompact
                ) {
                    selection = section
                }
            }
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        if mode.isCompact {
            HStack {
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.18), lineWidth: 3)
                    )
                    .help(statusText)
                Spacer()
            }
        } else {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.18), lineWidth: 3)
                    )
                Text(statusText)
                    .font(DS.Font.mono(10))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(DS.Palette.ink2)
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .loadingModel:              return DS.Palette.ink3
        case .idle:                      return Color(red: 0.165, green: 0.541, blue: 0.282)
        case .recording:                 return DS.Palette.accent
        case .transcribing, .correcting: return DS.Palette.highlight
        case .noModel:                   return DS.Palette.highlight
        case .noBrain:                   return DS.Palette.highlight
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .loadingModel: return "Loading model…"
        case .idle:         return "Ready · waiting for fn"
        case .recording:    return "Recording…"
        case .transcribing: return "Transcribing…"
        case .correcting:   return "Polishing…"
        case .noModel:      return "No voice model installed"
        case .noBrain:      return "No AI model installed"
        }
    }
}
