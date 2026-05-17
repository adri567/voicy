import SwiftUI

struct CycleBadge: View {
    let mode: Mode

    var body: some View {
        Group {
            if let emoji = mode.displayEmoji {
                Text(emoji)
                    .font(.system(size: 11))
            } else {
                // Raw / Developer / Email / Snippets — render the type's SF
                // Symbol instead of a flag/emoji. Sized to match the emoji bounds.
                Image(systemName: mode.type.systemImage)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 25, height: 25)
        .background(.black.opacity(0.8), in: Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
    }
}
