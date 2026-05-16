import SwiftUI

struct MainWindowView: View {

    var viewModel: RecordingViewModel
    var modeCycleService: ModeCycleService
    @State private var selection: SidebarSection = .home
    @State private var sidebarMode: SidebarMode = .full

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                MainWindowSidebar(
                    mode: sidebarMode,
                    selection: $selection,
                    viewModel: viewModel
                )
                .frame(width: sidebarMode == .full ? 256 : 64)

                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.Palette.paper)
            }
            .frame(minWidth: 1340, minHeight: 760)
            .background(DS.Palette.paper)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                            .help(sidebarHelp)
                    }
                    .keyboardShortcut("s", modifiers: [.command, .control])
                }
            }
            .toolbar(removing: .title)
            .toolbarBackground(.hidden, for: .windowToolbar)
        }
    }

    private var sidebarHelp: String {
        switch sidebarMode {
        case .full:    "Sidebar kompakt machen (⌃⌘S)"
        case .compact: "Sidebar vergrößern (⌃⌘S)"
        }
    }

    private func toggleSidebar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            sidebarMode = sidebarMode == .full ? .compact : .full
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .home:       HomeView(viewModel: viewModel) { selection = $0 }
        case .transcribe: TranscribeView()
        case .snippets:   SnippetsView()
        case .engine:     EngineView()
        case .brain:      BrainView()
        case .modes:      ModesView(cycle: modeCycleService)
        case .hotkey:     HotkeyView()
        case .settings:   SettingsView(viewModel: viewModel, cycle: modeCycleService)
        }
    }
}
