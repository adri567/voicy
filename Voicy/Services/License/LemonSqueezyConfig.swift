import Foundation

/// Public Lemon Squeezy store identifiers, loaded at runtime from a bundled
/// `LemonSqueezy.plist`. These aren't secrets (the store id and checkout URL are
/// visible to any buyer), but they're kept out of source per the project's
/// no-hardcoding rule — the real file is gitignored, with
/// `LemonSqueezy.example.plist` checked in as a template.
///
/// While the plist is missing or still holds placeholders (store id 0), product
/// verification is skipped so the activation flow stays developable before the
/// store exists. `isConfigured` reports whether real values are present.
nonisolated struct LemonSqueezyConfig: Sendable {
    let storeID: Int
    let variantIDs: Set<Int>
    let checkoutURL: URL

    /// True once a real store id is present — gates product verification.
    var isConfigured: Bool { storeID > 0 }

    /// Whether a license's `meta` matches our store and one of our variants.
    /// Always true while unconfigured, so placeholder builds never reject keys.
    func accepts(storeID: Int?, variantID: Int?) -> Bool {
        guard isConfigured else { return true }
        guard storeID == self.storeID, let variantID else { return false }
        return variantIDs.contains(variantID)
    }

    static let fallbackCheckoutURL = URL(string: "https://voicy.pro")!

    /// Reads the bundled plist; falls back to placeholders when it's absent.
    static func loadFromBundle(_ bundle: Bundle = .main) -> LemonSqueezyConfig {
        guard
            let url = bundle.url(forResource: "LemonSqueezy", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return LemonSqueezyConfig(storeID: 0, variantIDs: [], checkoutURL: fallbackCheckoutURL)
        }
        let storeID = dict["StoreID"] as? Int ?? 0
        let variants = (dict["VariantIDs"] as? [Int]).map(Set.init) ?? []
        let checkout = (dict["CheckoutURL"] as? String).flatMap { URL(string: $0) } ?? fallbackCheckoutURL
        return LemonSqueezyConfig(storeID: storeID, variantIDs: variants, checkoutURL: checkout)
    }
}
