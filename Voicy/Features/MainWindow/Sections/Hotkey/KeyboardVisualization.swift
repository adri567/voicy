import SwiftUI

struct KeyboardVisualization: View {
    private let rows: [[String]] = [
        ["esc","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"],
        ["~","1","2","3","4","5","6","7","8","9","0","-","="],
        ["tab","Q","W","E","R","T","Y","U","I","O","P","[","]"],
        ["caps","A","S","D","F","G","H","J","K","L",";","'","↩"],
        ["⇧","Z","X","C","V","B","N","M",",",".","/","⇧"],
        ["fn","⌃","⌥","⌘","space","⌘","⌥","◀","▼","▶"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "Magic Keyboard · live preview", color: DS.Palette.paper.opacity(0.45))
                .padding(.bottom, 16)

            VStack(spacing: 4) {
                ForEach(0..<rows.count, id: \.self) { ri in
                    HStack(spacing: 4) {
                        ForEach(0..<rows[ri].count, id: \.self) { ci in
                            keyCap(rows[ri][ci])
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack {
                Text("○ ready")
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.paper.opacity(0.5))
                Spacer()
                MetaLabel(text: "conflicts: none detected", color: DS.Palette.paper.opacity(0.4))
            }
            .padding(.top, 18)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(red: 0.165, green: 0.149, blue: 0.122), Color(red: 0.102, green: 0.094, blue: 0.078)],
                startPoint: .top, endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .shadow(color: .black.opacity(0.3), radius: 40, y: 20)
    }

    private func keyCap(_ label: String) -> some View {
        let isActive = label == "fn"
        let width: CGFloat = label == "space" ? 80 : (label.count > 1 && label != "↩" ? 30 : 22)

        return ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(isActive ? DS.Palette.accent : Color(red: 0.239, green: 0.220, blue: 0.188))
                .frame(height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: isActive ? DS.Palette.accent.opacity(0.5) : .clear, radius: 8)

            if label != "space" {
                Text(label)
                    .font(DS.Font.mono(label.count > 1 ? 8 : 10, weight: .medium))
                    .foregroundStyle(isActive ? DS.Palette.accentInk : DS.Palette.paper.opacity(0.6))
            }
        }
        .frame(width: width)
    }
}
