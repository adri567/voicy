import Foundation
import Synchronization
import Testing
@testable import Voicy

/// Canned HTTP reply for the client tests. Shared via a `Mutex` and the suite is
/// `.serialized` so parallel tests can't clobber each other's stub.
private struct Stub: Sendable {
    let statusCode: Int
    let body: String
}

private let stubBox = Mutex<Stub?>(nil)

/// `URLProtocol` that returns the current `stubBox` value (or fails the request
/// when nil, to exercise the transport-error path).
final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = stubBox.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("DefaultLemonSqueezyClient", .serialized)
struct LemonSqueezyClientTests {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private let activatedJSON = """
    {
      "activated": true,
      "error": null,
      "license_key": { "id": 1, "status": "active", "key": "KEY", "activation_limit": 1, "activation_usage": 1, "expires_at": null },
      "instance": { "id": "instance-abc", "name": "Mac", "created_at": "2026-01-01T00:00:00.000000Z" },
      "meta": { "store_id": 42, "variant_id": 7, "customer_email": "buyer@example.com" }
    }
    """

    @Test("activate parses the success payload")
    func activateParses() async throws {
        stubBox.withLock { $0 = Stub(statusCode: 200, body: activatedJSON) }
        let client = DefaultLemonSqueezyClient(session: makeSession())

        let result = try await client.activate(key: "KEY", instanceName: "Mac")

        #expect(result.valid)
        #expect(result.status == .active)
        #expect(result.instanceID == "instance-abc")
        #expect(result.storeID == 42)
        #expect(result.variantID == 7)
        #expect(result.customerEmail == "buyer@example.com")
    }

    @Test("a failed-validation body decodes without throwing")
    func validateInvalidBody() async throws {
        let body = """
        { "valid": false, "error": "license_key not found", "license_key": null, "instance": null, "meta": null }
        """
        stubBox.withLock { $0 = Stub(statusCode: 404, body: body) }
        let client = DefaultLemonSqueezyClient(session: makeSession())

        let result = try await client.validate(key: "BAD", instanceID: "I")

        #expect(result.valid == false)
        #expect(result.error == "license_key not found")
        #expect(result.status == .inactive) // unmappable → defaulted
    }

    @Test("a transport failure throws LemonSqueezyClientError")
    func transportThrows() async {
        stubBox.withLock { $0 = nil }
        let client = DefaultLemonSqueezyClient(session: makeSession())

        await #expect(throws: LemonSqueezyClientError.self) {
            try await client.validate(key: "K", instanceID: "I")
        }
    }
}
