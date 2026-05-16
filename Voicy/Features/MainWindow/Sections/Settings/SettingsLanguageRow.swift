import SwiftUI

struct SettingsLanguageRow: View {

    @Bindable var cycle: ModeCycleService
    @State private var open = false

    private var current: AppLanguage { cycle.sourceLanguage }

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("You speak in")
                    .font(DS.Font.sans(14, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
                Text("The default language Voicy transcribes. Every Translate mode uses this as its source — change here, and every mode re-points.")
                    .font(DS.Font.sans(12))
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink3)
            }
            Spacer(minLength: 18)
            pill
        }
        .padding(.vertical, 18)
    }

    private var pill: some View {
        Button(action: { open.toggle() }) {
            HStack(spacing: 10) {
                Text(current.flag).font(.system(size: 20))
                Text(current.native)
                    .font(DS.Font.sans(14, weight: .semibold))
                    .foregroundStyle(DS.Palette.ink)
                Text(current.code.uppercased())
                    .font(DS.Font.mono(10))
                    .tracking(0.6)
                    .foregroundStyle(DS.Palette.ink3)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Palette.ink3)
                    .rotationEffect(.degrees(open ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DS.Palette.paper, in: Capsule())
            .overlay(
                Capsule().stroke(open ? DS.Palette.ink : DS.Palette.ink.opacity(0.18), lineWidth: 1)
            )
            .frame(minWidth: 200)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $open, arrowEdge: .top) {
            SourceLanguageGrid(selected: current.code) { code in
                cycle.setSourceLanguage(code)
                open = false
            }
        }
    }
}
