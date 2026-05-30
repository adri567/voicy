import FactoryKit
import Testing
@testable import Voicy

@MainActor
@Suite("UpdateService")
struct UpdateServiceTests {

    @Test("updateService resolves the registered implementation and forwards checks")
    func resolvesAndForwards() {
        let mock = MockUpdateService()
        Container.shared.updateService.register { mock }
        defer { Container.shared.reset() }

        let resolved = Container.shared.updateService()
        #expect(resolved.canCheckForUpdates)

        resolved.checkForUpdates()
        resolved.checkForUpdates()
        #expect(mock.checkCount == 2)
    }
}
