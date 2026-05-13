import Foundation
import Observation

/// Holds the language selection (1 source + up to 3 optional targets) and the
/// cycle step driven by `fn + →/←` during recording.
///
/// - `step == 0` → source is active (no translation, raw transcript).
/// - `step ∈ 1...3` → a non-nil target language is active.
///
/// Empty target slots are skipped during cycling: `fn + →` advances only to
/// slots that contain a language. If no targets are set, `fn + →` is a no-op.
@MainActor
@Observable
final class LanguageCycleService {

    private(set) var source: AppLanguage
    private(set) var targets: [AppLanguage?]   // always 3 elements, each may be nil
    private(set) var step: Int = 0             // 0 = source · 1...3 = target index + 1

    init() {
        let defaults = UserDefaults.standard
        let storedSource = defaults.string(forKey: Preferences.Key.languageSourceCode) ?? "de"
        let storedTargets = defaults.stringArray(forKey: Preferences.Key.languageTargetCodes) ?? []
        self.source = LanguageCatalog.language(for: storedSource)
        var slots: [AppLanguage?] = [nil, nil, nil]
        for (i, code) in storedTargets.prefix(3).enumerated() where !code.isEmpty {
            slots[i] = LanguageCatalog.language(for: code)
        }
        self.targets = slots
    }

    // MARK: Derived

    var activeLanguage: AppLanguage {
        activeTarget ?? source
    }

    var activeTarget: AppLanguage? {
        guard step > 0, targets.indices.contains(step - 1) else { return nil }
        return targets[step - 1]
    }

    // MARK: Cycle (driven by hotkey)

    /// Advance to the next non-empty target slot. No-op if there is none.
    func cycleForward() {
        guard step < 3 else { return }
        for candidate in (step + 1)...3 where targets[candidate - 1] != nil {
            step = candidate
            return
        }
    }

    /// Step back to the previous non-empty target slot, or to source (0).
    func cycleBackward() {
        guard step > 0 else { return }
        for candidate in stride(from: step - 1, through: 1, by: -1) where targets[candidate - 1] != nil {
            step = candidate
            return
        }
        step = 0
    }

    func resetCycle() {
        step = 0
    }

    func setStep(_ value: Int) {
        guard (0...3).contains(value) else { return }
        // Source slot is always valid; target slots only if filled.
        if value > 0, targets[value - 1] == nil { return }
        step = value
    }

    // MARK: Settings UI

    func setSource(_ code: String) {
        let lang = LanguageCatalog.language(for: code)
        source = lang
        UserDefaults.standard.set(lang.code, forKey: Preferences.Key.languageSourceCode)
    }

    func setTarget(at index: Int, code: String) {
        guard targets.indices.contains(index) else { return }
        targets[index] = LanguageCatalog.language(for: code)
        persistTargets()
    }

    func clearTarget(at index: Int) {
        guard targets.indices.contains(index) else { return }
        targets[index] = nil
        if step == index + 1 { resetCycle() }
        persistTargets()
    }

    private func persistTargets() {
        let codes = targets.map { $0?.code ?? "" }
        UserDefaults.standard.set(codes, forKey: Preferences.Key.languageTargetCodes)
    }
}
