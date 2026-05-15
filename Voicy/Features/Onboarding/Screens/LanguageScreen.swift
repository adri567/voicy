import SwiftUI

struct LanguageScreen: View {
    @Bindable var state: OnboardingState

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ScreenShell(
            chapter: "05",
            kicker: "Chapter 05 — Tongue",
            title: AnyView(titleView),
            lead: "Pick the one you'll dictate in most. Voicy will optimise the engine for it. You can switch later in Settings — and Voicy still understands code-switching mid-sentence.",
            body: { leftBody },
            leftFooter: { footer },
            rightCol: { rightStage }
        )
    }

    private var titleView: some View {
        (Text("Which ")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink)
         + Text("language")
            .font(DS.Font.serifItalic(52, weight: .medium))
            .foregroundStyle(DS.Palette.accent)
         + Text(" will you speak?")
            .font(DS.Font.serif(52, weight: .medium))
            .foregroundStyle(DS.Palette.ink))
        .tracking(-1.0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leftBody: some View {
        let current = state.pickedLanguage
        return VStack(alignment: .leading, spacing: 10) {
            MetaLabel(text: "Selected")
            HStack(spacing: 14) {
                Text(current.flag).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.native)
                        .font(DS.Font.serif(22, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                    Text("\(current.code.uppercased()) · primary engine bias")
                        .font(DS.Font.mono(9))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.ink3)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.panel)
                    .stroke(DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
    }

    private var footer: some View {
        NavFooter(
            primary: "Continue →",
            onContinue: { state.next() },
            note: "Engine tuned for \(state.pickedLanguage.code.uppercased())"
        )
    }

    @ViewBuilder
    private var rightStage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                MetaLabel(text: "◆ Pick one — \(LanguageCatalog.all.count) supported")

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(LanguageCatalog.all) { lang in
                        languageTile(lang)
                    }
                }
            }
            .padding(36)
        }
    }

    private func languageTile(_ lang: AppLanguage) -> some View {
        let active = state.languageCode == lang.code
        return Button(action: { state.languageCode = lang.code }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lang.flag).font(.system(size: 22))
                    Spacer()
                    if active {
                        ZStack {
                            Circle().fill(DS.Palette.accent).frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                Text(lang.native)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(active ? DS.Palette.ink : DS.Palette.ink2)
                Text(lang.code.uppercased())
                    .font(DS.Font.mono(8))
                    .tracking(1.0)
                    .foregroundStyle(DS.Palette.ink3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(active ? DS.Palette.paper : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(active ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
