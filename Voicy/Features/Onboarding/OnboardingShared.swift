import SwiftUI

// MARK: - Two-column screen scaffold
// Editorial left column (title + lead + body + footer), right column (form / illustration).

struct ScreenShell<LeftBody: View, LeftFooter: View, Right: View>: View {
    let chapter: String
    let kicker: String
    let titleView: AnyView
    let lead: String?
    let leftBody: LeftBody
    let leftFooter: LeftFooter
    let rightCol: Right

    init(
        chapter: String,
        kicker: String,
        title: AnyView,
        lead: String? = nil,
        @ViewBuilder body leftBody: () -> LeftBody = { EmptyView() },
        @ViewBuilder leftFooter: () -> LeftFooter = { EmptyView() },
        @ViewBuilder rightCol: () -> Right
    ) {
        self.chapter = chapter
        self.kicker = kicker
        self.titleView = title
        self.lead = lead
        self.leftBody = leftBody()
        self.leftFooter = leftFooter()
        self.rightCol = rightCol()
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left column
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ \(kicker)", color: DS.Palette.accent)

                titleView
                    .padding(.top, 20)

                if let lead {
                    Text(lead)
                        .font(DS.Font.sans(16))
                        .lineSpacing(4)
                        .foregroundStyle(DS.Palette.ink2)
                        .frame(maxWidth: 460, alignment: .leading)
                        .padding(.top, 22)
                }

                leftBody
                    .padding(.top, 22)

                Spacer(minLength: 16)

                leftFooter
            }
            .padding(.horizontal, 56)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DS.Palette.paper)
            .overlay(alignment: .trailing) {
                Rectangle().fill(DS.Palette.ruleSoft).frame(width: 1)
            }

            // Right column
            rightCol
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DS.Palette.paper2)
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.sans(13, weight: .semibold))
                .foregroundStyle(disabled ? DS.Palette.ink.opacity(0.5) : DS.Palette.paper)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(
                    Capsule().fill(disabled ? DS.Palette.ink.opacity(0.18) : DS.Palette.ink)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.sans(13, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
                .overlay(
                    Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Footer with primary + optional skip + note

struct NavFooter: View {
    let primary: String
    var primaryDisabled: Bool = false
    let onContinue: () -> Void
    var secondary: String? = nil
    var onSkip: (() -> Void)? = nil
    var note: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            PrimaryButton(title: primary, disabled: primaryDisabled, action: onContinue)
            if let secondary, let onSkip {
                GhostButton(title: secondary, action: onSkip)
            }
            if let note, !note.isEmpty {
                MetaLabel(text: note)
                    .padding(.leading, 6)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
}

// MARK: - Bullet row used in mic/a11y screens

struct OnboardingBulletRow: View {
    let glyph: String?
    let label: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                if let glyph {
                    Text(glyph)
                        .font(DS.Font.sans(15, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(DS.Palette.paperCard, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                }
            }
            .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DS.Font.serif(17, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                Text(desc)
                    .font(DS.Font.sans(13))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Rectangle().fill(DS.Palette.ruleSoft).frame(height: 1)
        }
    }
}

// MARK: - Spec column (Label / Value)

struct SpecBlock: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MetaLabel(text: label)
                .font(DS.Font.mono(8, weight: .regular))
            Text(value)
                .font(DS.Font.mono(12, weight: .medium))
                .foregroundStyle(DS.Palette.ink2)
        }
    }
}

// MARK: - Kbd chip

struct OnboardingKbd: View {
    let label: String
    var dark: Bool = false
    var body: some View {
        Text(label)
            .font(DS.Font.mono(11, weight: .medium))
            .foregroundStyle(dark ? DS.Palette.accentInk : DS.Palette.ink)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(dark ? Color(red: 0.165, green: 0.149, blue: 0.122) : DS.Palette.paperCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(dark ? Color.white.opacity(0.1) : DS.Palette.ink.opacity(0.18), lineWidth: 1)
            )
    }
}

// MARK: - Progress bar

struct OnboardingProgressBar: View {
    let value: Double // 0…100

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.Palette.ink.opacity(0.1))
                Capsule()
                    .fill(DS.Palette.accent)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 100) / 100))
            }
        }
        .frame(height: 6)
    }
}
