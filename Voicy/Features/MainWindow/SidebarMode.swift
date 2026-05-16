enum SidebarMode {
    case full, compact

    var isCompact: Bool { self == .compact }
}
