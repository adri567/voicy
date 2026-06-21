import FactoryKit
import Foundation
import Observation

@Observable @MainActor
final class SnippetsViewModel {

    @ObservationIgnored
    @Injected(\.snippetService) private var service

    @ObservationIgnored
    @Injected(\.entitlementService) private var entitlement

    private(set) var snippets: [SnippetDTO] = []
    var errorMessage: String?

    /// Whether the user may create another snippet under their plan. Free is
    /// capped at `PlanLimits.freeSnippets`; Pro (a `nil` limit) is unlimited.
    /// Editing an existing snippet is never gated — only new creation.
    var canCreateSnippet: Bool {
        guard let max = entitlement.maxSnippets else { return true }
        return snippets.count < max
    }

    func reload() async {
        do {
            snippets = try await service.all()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func persist(_ draft: SnippetDraft) async {
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
