import SwiftUI

// MARK: - Editorial Palette
// Source: design bundle voicy/project/styles.css (:root variables)
// TODO(design): replace system fonts with Lora (serif), Inter Tight (sans),
// JetBrains Mono (mono). Currently using SwiftUI's system designs which map
// to New York (serif), SF Pro (sans), SF Mono (mono) — visually close but
// not pixel-identical to the Claude Design mockups.

enum DS {

    enum Palette {
        static let paper        = Color(red: 1.00, green: 1.00, blue: 1.00)   // #ffffff
        static let paper2       = Color(red: 0.969, green: 0.965, blue: 0.953) // #f7f6f3
        static let paper3       = Color(red: 0.937, green: 0.929, blue: 0.917) // #efedea
        static let paperCard    = Color(red: 0.969, green: 0.965, blue: 0.953) // #f7f6f3
        static let ink          = Color(red: 0.102, green: 0.094, blue: 0.078) // #1a1814
        static let ink2         = Color(red: 0.239, green: 0.220, blue: 0.188) // #3d3830
        static let ink3         = Color(red: 0.502, green: 0.471, blue: 0.408) // #807868
        static let accent       = Color(red: 0.753, green: 0.263, blue: 0.165) // #c0432a
        static let accent2      = Color(red: 0.122, green: 0.239, blue: 0.165) // #1f3d2a
        static let highlight    = Color(red: 0.957, green: 0.773, blue: 0.294) // #f4c54b
        static let ruleSoft     = Color.black.opacity(0.07)
        static let ruleSofter   = Color.black.opacity(0.04)
        static let accentInk    = Color(red: 1.0, green: 0.961, blue: 0.882)   // #fff5e1
    }

    enum Font {
        // Serif — display + akzent
        static func serif(_ size: CGFloat, weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        static func serifItalic(_ size: CGFloat, weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif).italic()
        }
        // Sans — UI + body
        static func sans(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        // Mono — meta + timestamps
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }

    enum Radius {
        static let panel: CGFloat = 20
        static let card: CGFloat = 22
        static let pill: CGFloat = 100
        static let kbd: CGFloat = 7
        static let small: CGFloat = 10
    }

    enum Spacing {
        static let pageHPadding: CGFloat = 56
        static let pageTop: CGFloat = 36
        static let sectionGap: CGFloat = 32
    }
}

// MARK: - View modifiers

struct PanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: DS.Radius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
    }
}

struct TagPillModifier: ViewModifier {
    var solid: Bool = false
    var accent: Bool = false

    func body(content: Content) -> some View {
        content
            .font(DS.Font.mono(10, weight: .regular))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .foregroundStyle(textColor)
            .background(background, in: Capsule())
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
    }

    private var textColor: Color {
        if accent { return DS.Palette.accentInk }
        if solid  { return DS.Palette.paper }
        return DS.Palette.ink2
    }
    private var background: Color {
        if accent { return DS.Palette.accent }
        if solid  { return DS.Palette.ink }
        return .clear
    }
    private var borderColor: Color {
        if accent { return DS.Palette.accent }
        if solid  { return DS.Palette.ink }
        return DS.Palette.ruleSoft
    }
}

extension View {
    func dsPanel() -> some View { modifier(PanelModifier()) }
    func dsTag(solid: Bool = false, accent: Bool = false) -> some View {
        modifier(TagPillModifier(solid: solid, accent: accent))
    }
}

// MARK: - Reusable bits

struct MetaLabel: View {
    let text: String
    var color: Color = DS.Palette.ink3
    var body: some View {
        Text(text)
            .font(DS.Font.mono(10, weight: .regular))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

struct SoftDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Palette.ruleSoft)
            .frame(height: 1)
    }
}
