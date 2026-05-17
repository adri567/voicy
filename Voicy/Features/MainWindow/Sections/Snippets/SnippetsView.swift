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
            "Delete snippet?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { snippet in
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                let id = snippet.id
                pendingDelete = nil
                Task { await viewModel.delete(id: id) }
            }
        } message: { snippet in
            Text("“\(snippet.triggers.first ?? "")” will be permanently deleted.")
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
            Text("No snippets yet — create your first.")
                .font(DS.Font.sans(14))
                .foregroundStyle(DS.Palette.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .dsPanel()
    }
}
