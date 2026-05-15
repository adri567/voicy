import FactoryKit
import SwiftUI

struct SnippetsView: View {

    @State private var viewModel = SnippetsViewModel()
    @State private var editing: SnippetDraft?
    @State private var pendingDelete: SnippetDTO?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.top, DS.Spacing.pageTop)

                SoftDivider()
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.vertical, 32)

                library
                    .padding(.horizontal, DS.Spacing.pageHPadding)
                    .padding(.bottom, 56)
            }
        }
        .task { await viewModel.reload() }
        .sheet(item: $editing) { draft in
            SnippetEditor(draft: draft) { result in
                Task { await viewModel.persist(result); editing = nil }
            } onCancel: {
                editing = nil
            }
        }
        .alert(
            "Snippet löschen?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { snippet in
            Button("Abbrechen", role: .cancel) { pendingDelete = nil }
            Button("Löschen", role: .destructive) {
                let id = snippet.id
                pendingDelete = nil
                Task { await viewModel.delete(id: id) }
            }
        } message: { snippet in
            Text("„\(snippet.triggers.first ?? "")" + "\" wird permanent gelöscht.")
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        HStack(alignment: .top, spacing: 56) {
            VStack(alignment: .leading, spacing: 0) {
                MetaLabel(text: "◆ The Shortcuts", color: DS.Palette.accent)
                    .padding(.bottom, 14)

                Text("Speak less, \(Text("paste").italic().foregroundColor(DS.Palette.accent)) more.")
                    .font(DS.Font.serif(54))
                    .tracking(-1.0)
                    .lineSpacing(2)
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.bottom, 18)

                Text("Define a trigger phrase. When you say it during a recording, Voicy replaces the phrase with the saved text — deterministically, no AI involved. Switch your mode reel to \(Text("Snippets").italic().foregroundColor(DS.Palette.ink)) to activate.")
                    .font(DS.Font.sans(16))
                    .lineSpacing(4)
                    .foregroundStyle(DS.Palette.ink2)
                    .frame(maxWidth: 560, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statsCard
                .frame(width: 320)
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetaLabel(text: "By the numbers", color: DS.Palette.paper.opacity(0.6))
                .padding(.bottom, 14)

            statBlock(label: "Snippets", value: "\(viewModel.snippets.count)")
                .padding(.bottom, 14)
            statBlock(label: "Trigger phrases", value: "\(totalTriggers)")
                .padding(.bottom, 14)
            statBlock(label: "Enabled", value: "\(enabledCount)")
        }
        .padding(28)
        .background(DS.Palette.ink, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 12)
    }

    private func statBlock(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(value)
                .font(DS.Font.serif(36))
                .foregroundStyle(DS.Palette.paper)
            Text(label)
                .font(DS.Font.sans(12))
                .foregroundStyle(DS.Palette.paper.opacity(0.6))
        }
    }

    private var totalTriggers: Int {
        viewModel.snippets.reduce(0) { $0 + $1.triggers.count }
    }

    private var enabledCount: Int {
        viewModel.snippets.filter(\.enabled).count
    }

    // MARK: - Library

    private var library: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your \(Text("library").italic().foregroundColor(DS.Palette.ink))")
                    .font(DS.Font.serif(26))
                    .tracking(-0.3)
                    .foregroundStyle(DS.Palette.ink2)

                Spacer()

                Button(action: { editing = SnippetDraft() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("New snippet")
                            .font(DS.Font.sans(11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Palette.paper)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DS.Palette.ink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 20)

            if viewModel.snippets.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.snippets.enumerated()), id: \.element.id) { idx, snippet in
                        SnippetRow(
                            snippet: snippet,
                            index: idx + 1,
                            first: idx == 0,
                            onEdit: { editing = SnippetDraft(snippet) },
                            onToggle: { Task { await viewModel.toggleEnabled(id: snippet.id) } },
                            onDelete: { pendingDelete = snippet }
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 8)
                .dsPanel()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DS.Font.sans(12))
                    .foregroundStyle(DS.Palette.accent)
                    .padding(.top, 20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(DS.Palette.ink3)
            Text("Noch keine Snippets — leg dein erstes an.")
                .font(DS.Font.sans(14))
                .foregroundStyle(DS.Palette.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .dsPanel()
    }
}

// MARK: - Snippet Row

private struct SnippetRow: View {
    let snippet: SnippetDTO
    let index: Int
    let first: Bool
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                Text(String(format: "%02d", index))
                    .font(DS.Font.serifItalic(36))
                    .foregroundStyle(snippet.enabled ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    triggerChips
                    Text(snippet.replacement)
                        .font(DS.Font.sans(14))
                        .lineSpacing(3)
                        .foregroundStyle(DS.Palette.ink)
                        .frame(maxWidth: 580, alignment: .leading)
                        .opacity(snippet.enabled ? 1.0 : 0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actionBlock
                    .frame(width: 160, alignment: .trailing)
            }
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
    }

    private var triggerChips: some View {
        HStack(spacing: 6) {
            ForEach(snippet.triggers, id: \.self) { trigger in
                Text("„\(trigger)\"")
                    .font(DS.Font.serifItalic(15))
                    .foregroundStyle(DS.Palette.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.04), in: Capsule())
            }
        }
    }

    private var actionBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(snippet.enabled ? "Enabled" : "Disabled")
                .dsTag(solid: false, accent: snippet.enabled)

            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Image(systemName: snippet.enabled ? "pause" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.ink)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help(snippet.enabled ? "Disable" : "Enable")

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.ink)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Edit")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Palette.accent)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DS.Palette.accent.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
    }
}

// MARK: - Editor Sheet

private struct SnippetDraft: Identifiable {
    let id: UUID
    let existingID: UUID?
    var triggers: [String]
    var replacement: String
    var enabled: Bool

    init() {
        self.id = UUID()
        self.existingID = nil
        self.triggers = [""]
        self.replacement = ""
        self.enabled = true
    }

    init(_ snippet: SnippetDTO) {
        self.id = UUID()
        self.existingID = snippet.id
        self.triggers = snippet.triggers
        self.replacement = snippet.replacement
        self.enabled = snippet.enabled
    }
}

private struct SnippetEditor: View {
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
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .font(DS.Font.sans(13, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))

                Spacer()

                Button(action: { onSave(draft) }) {
                    Text(draft.existingID == nil ? "Create" : "Save")
                        .font(DS.Font.sans(13, weight: .semibold))
                        .foregroundStyle(DS.Palette.paper)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(canSave ? DS.Palette.ink : DS.Palette.ink3, in: Capsule())
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

// MARK: - ViewModel

@Observable
final class SnippetsViewModel {

    @ObservationIgnored
    @Injected(\.snippetService) private var service

    private(set) var snippets: [SnippetDTO] = []
    var errorMessage: String?

    func reload() async {
        do {
            snippets = try await service.all()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    fileprivate func persist(_ draft: SnippetDraft) async {
        do {
            if let existingID = draft.existingID {
                try await service.update(
                    id: existingID,
                    triggers: draft.triggers,
                    replacement: draft.replacement,
                    enabled: draft.enabled
                )
            } else {
                _ = try await service.create(
                    triggers: draft.triggers,
                    replacement: draft.replacement
                )
            }
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await service.delete(id: id)
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleEnabled(id: UUID) async {
        guard let snippet = snippets.first(where: { $0.id == id }) else { return }
        do {
            try await service.update(
                id: id,
                triggers: snippet.triggers,
                replacement: snippet.replacement,
                enabled: !snippet.enabled
            )
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
