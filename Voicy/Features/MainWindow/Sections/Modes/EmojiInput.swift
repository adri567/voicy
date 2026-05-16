import SwiftUI

struct EmojiInput: View {
    let value: String
    let onChange: (String) -> Void

    var body: some View {
        TextField("", text: Binding(get: { value }, set: { v in onChange(String(v.prefix(2))) }))
            .textFieldStyle(.plain)
            .font(.system(size: 22))
            .foregroundStyle(DS.Palette.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(DS.Palette.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Palette.ruleSoft, lineWidth: 1))
    }
}
