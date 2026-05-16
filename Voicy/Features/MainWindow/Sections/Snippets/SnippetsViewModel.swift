import FactoryKit
import Foundation
import Observation

@Observable @MainActor
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
