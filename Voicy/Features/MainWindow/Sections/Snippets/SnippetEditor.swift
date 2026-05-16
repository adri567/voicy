import SwiftUI

struct SnippetEditor: View {
    @State var draft: SnippetDraft
    let onSave: (SnippetDraft) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(draft.existingID == nil ? "New snippet" : "Edit snippet")
                .font(DS.Font.serif(28))
                .foregroundStyle(DS.Palette.ink)
                .padding(.bottom, 4)

            Text("A trigger is the phrase you'll speak. The replacement is what gets pasted in its place.")
                .font(DS.Font.sans(13))
                .foregroundStyle(DS.Palette.ink2)
                .padding(.bottom, 24)

            MetaLabel(text: "Trigger phrases")
                .padding(.bottom, 8)

            VStack(spacing: 6) {
                ForEach(draft.triggers.indices, id: \.self) { idx in
                    triggerRow(idx: idx)
                }
                Button(action: { draft.triggers.append("") }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("Add alias")
                            .font(DS.Font.sans(11, weight: .medium))
                    }
                    .foregroundStyle(DS.Palette.ink2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 22)

            MetaLabel(text: "Replacement text")
                .padding(.bottom, 8)

            TextEditor(text: $draft.replacement)
                .font(DS.Font.sans(13))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))
                .padding(.bottom, 16)

            Toggle(isOn: $draft.enabled) {
                Text("Enabled")
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
            }
            .toggleStyle(.switch)
            .padding(.bottom, 24)

            HStack {
                Button(action: { onCancel() }) {
                    Text("Cancel")
                        .font(DS.Font.sans(13, weight: .medium))
                        .foregroundStyle(DS.Palette.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { onSave(draft) }) {
                    Text(draft.existingID == nil ? "Create" : "Save")
                        .font(DS.Font.sans(13, weight: .semibold))
                        .foregroundStyle(DS.Palette.paper)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(canSave ? DS.Palette.ink : DS.Palette.ink3, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
        .padding(32)
        .frame(width: 520)
        .background(DS.Palette.paper)
        .preferredColorScheme(.light)
    }

    private func triggerRow(idx: Int) -> some View {
        HStack(spacing: 8) {
            TextField("e.g. best regards", text: Binding(
                get: { draft.triggers[idx] },
                set: { draft.triggers[idx] = $0 }
            ))
            .textFieldStyle(.plain)
            .font(DS.Font.sans(13))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Palette.ruleSoft, lineWidth: 1))

            if draft.triggers.count > 1 {
                Button(action: { draft.triggers.remove(at: idx) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Palette.ink2)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.ruleSoft, lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var canSave: Bool {
        let nonEmptyTriggers = draft.triggers.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let hasReplacement = !draft.replacement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return nonEmptyTriggers && hasReplacement
    }
}
