import SwiftUI

struct HistoryFilterChips: View {
    @Binding var active: HistoryFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button(action: { active = filter }) {
                    Text(filter.label)
                        .font(DS.Font.mono(10))
                        .tracking(1)
                        .foregroundStyle(active == filter ? DS.Palette.paper : DS.Palette.ink2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(active == filter ? DS.Palette.ink : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(active == filter ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
