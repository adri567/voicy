import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable {
    case home, snippets, engine, brain, languages, hotkey, settings
    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:      "Home"
        case .snippets:  "Snippets"
        case .engine:    "Engine"
        case .brain:     "Brain"
        case .languages: "Languages"
        case .hotkey:    "Hotkey"
        case .settings:  "Settings"
        }
    }

    var hint: String {
        switch self {
        case .home:      "Verlauf"
        case .snippets:  "Shortcuts"
        case .engine:    "Voice models"
        case .brain:     "Language models"
        case .languages: "Modes"
        case .hotkey:    "Trigger"
        case .settings:  "Preferences"
        }
    }

    var systemImage: String {
        switch self {
        case .home:      "house"
        case .snippets:  "doc.on.doc"
        case .engine:    "gearshape.2"
        case .brain:     "brain"
        case .languages: "character.bubble"
        case .hotkey:    "keyboard"
        case .settings:  "slider.horizontal.3"
        }
    }
}

enum SidebarMode {
    case full, compact

    var isCompact: Bool { self == .compact }
}

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
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .loadingModel: return "Loading model…"
        case .idle:         return "Ready · waiting for fn"
        case .recording:    return "Recording…"
        case .transcribing: return "Transcribing…"
        case .correcting:   return "Polishing…"
        }
    }
}

private struct NavItem: View {
    let section: SidebarSection
    let isActive: Bool
    let isCompact: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            if isCompact {
                Image(systemName: section.systemImage)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 36)
                    .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.small))
                    .contentShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    .help(section.label)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(iconColor)
                        .frame(width: 18, height: 18)

                    Text(section.label)
                        .font(DS.Font.sans(14, weight: .medium))
                        .foregroundStyle(labelColor)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.small))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.small))
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var iconColor: Color {
        if isActive { return DS.Palette.accent }
        return DS.Palette.ink3
    }

    private var labelColor: Color {
        if isActive { return DS.Palette.ink }
        if isHovering { return DS.Palette.ink }
        return DS.Palette.ink2
    }

    private var background: Color {
        if isActive { return Color.black.opacity(0.08) }
        if isHovering { return Color.black.opacity(0.04) }
        return .clear
    }
}
