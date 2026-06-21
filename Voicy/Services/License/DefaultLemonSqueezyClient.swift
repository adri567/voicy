import Foundation

/// `URLSession`-backed Lemon Squeezy license client. `nonisolated` so the HTTP
/// round-trips don't pin to the main actor; `URLSession` is injectable for
/// `URLProtocol`-based tests.
nonisolated final class DefaultLemonSqueezyClient: LemonSqueezyClient {

    private static let base = URL(string: "https://api.lemonsqueezy.com/v1/licenses/")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func activate(key: String, instanceName: String) async throws -> LicenseValidation {
        try await post("activate", ["license_key": key, "instance_name": instanceName])
    }

    func validate(key: String, instanceID: String) async throws -> LicenseValidation {
        try await post("validate", ["license_key": key, "instance_id": instanceID])
    }

    func deactivate(key: String, instanceID: String) async throws {
        _ = try await post("deactivate", ["license_key": key, "instance_id": instanceID])
    }

    private func post(_ path: String, _ params: [String: String]) async throws -> LicenseValidation {
        var request = URLRequest(url: Self.base.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncode(params)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LemonSqueezyClientError.transport(error.localizedDescription)
        }

        // The license API replies 200 on success and 400/404 with a JSON body
        // describing the failure — both carry a usable payload. Anything else is
        // unexpected (5xx, HTML error pages, …).
        guard
            let http = response as? HTTPURLResponse,
            (200...499).contains(http.statusCode),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw LemonSqueezyClientError.badResponse
        }
        return Self.parse(json)
    }

    private static func parse(_ json: [String: Any]) -> LicenseValidation {
        let licenseKey = json["license_key"] as? [String: Any]
        let instance = json["instance"] as? [String: Any]
        let meta = json["meta"] as? [String: Any]
        // activate → `activated`, validate → `valid`, deactivate → `deactivated`.
        let valid = (json["valid"] as? Bool)
            ?? (json["activated"] as? Bool)
            ?? (json["deactivated"] as? Bool)
            ?? false
        let statusString = (licenseKey?["status"] as? String) ?? ""
        return LicenseValidation(
            valid: valid,
            error: json["error"] as? String,
            status: LicenseStatus(rawValue: statusString) ?? .inactive,
            instanceID: instance?["id"] as? String,
            storeID: meta?["store_id"] as? Int,
            variantID: meta?["variant_id"] as? Int,
            customerEmail: meta?["customer_email"] as? String,
            instanceName: instance?["name"] as? String
        )
    }

    private static func formEncode(_ params: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }
}
