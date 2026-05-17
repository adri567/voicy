import Foundation
import Observation

/// Holds the user's Mode-Reel (4–6 slots) and the cycle step driven by
/// `fn + →/←` during recording. The source language is global to the app —
/// every Translate slot reads it from here, every change re-validates the
/// existing Translate slots.
@MainActor
@Observable
final class ModeCycleService {

    /// Minimum reel size: only Raw needs to be present. Slot 0 is permanently
    /// locked as Raw, so the user can never go below this.
    static let minSlots = 1
    static let maxSlots = 6

    private(set) var modes: [Mode]
    private(set) var step: Int = 0
    private(set) var sourceLanguage: AppLanguage

    init() {
        let defaults = UserDefaults.standard
        let storedSource = defaults.string(forKey: Preferences.Key.sourceLanguageCode) ?? "de"
        self.sourceLanguage = LanguageCatalog.language(for: storedSource)

        if let data = defaults.data(forKey: Preferences.Key.modesReel),
           let decoded = try? JSONDecoder().decode([Mode].self, from: data),
           !decoded.isEmpty {
            self.modes = decoded
        } else {
            self.modes = DefaultReel.make(sourceCode: storedSource)
        }
        // Validate count bounds. Defensive — should never trip in production
        // but guards us if a future migration leaves the array malformed.
        if modes.count < Self.minSlots {
            while modes.count < Self.minSlots { modes.append(Mode(type: .raw)) }
        } else if modes.count > Self.maxSlots {
            modes = Array(modes.prefix(Self.maxSlots))
        }
        // Slot 0 is the immutable Raw fallback — guarantee it.
        if modes.first?.type != .raw {
            modes.insert(Mode(type: .raw), at: 0)
            if modes.count > Self.maxSlots { modes = Array(modes.prefix(Self.maxSlots)) }
        }
        reconcileTargets()
    }

    /// True when the slot at `index` is the locked default Raw slot.
    func isLocked(at index: Int) -> Bool { index == 0 }
    func isLocked(id: UUID) -> Bool {
        modes.first?.id == id
    }

    // MARK: - Derived

    var activeMode: Mode { modes[step] }

    // MARK: - Cycle (driven by hotkey)

    /// Advance one slot. Wraps from the last slot back to the first.
    func cycleForward() {
        step = (step + 1) % modes.count
        SoundService.playModeSwitch()
    }

    /// Step one slot back. Wraps from the first slot to the last.
    func cycleBackward() {
        step = (step - 1 + modes.count) % modes.count
        SoundService.playModeSwitch()
    }

    func resetCycle() {
        step = 0
    }

    func setStep(_ value: Int) {
        guard modes.indices.contains(value) else { return }
        step = value
    }

    // MARK: - Editor mutations (Modes page)

    func update(id: UUID, mutate: (inout Mode) -> Void) {
        guard let idx = modes.firstIndex(where: { $0.id == id }) else { return }
        var copy = modes[idx]
        let originalType = copy.type
        mutate(&copy)
        // Slot 0 is locked as the Raw fallback: refuse any type change.
        if idx == 0 { copy.type = originalType }
        modes[idx] = copy
        persistModes()
    }

    @discardableResult
    func addMode() -> Mode? {
        guard modes.count < Self.maxSlots else { return nil }
        // New slots default to .translate (not .raw — that's the locked slot 0).
        let target = LanguageCatalog.all.first(where: { $0.code != sourceLanguage.code })?.code ?? "en"
        let new = Mode(type: .translate, targetCode: target)
        modes.append(new)
        persistModes()
        return new
    }

    func removeMode(id: UUID) {
        guard modes.count > Self.minSlots else { return }
        guard let idx = modes.firstIndex(where: { $0.id == id }) else { return }
        // Slot 0 (locked Raw) can never be removed.
        guard idx != 0 else { return }
        modes.remove(at: idx)
        // Keep step inside bounds. If we removed the active slot, fall back
        // to the previous slot (or 0 if we removed the very first one).
        if step >= modes.count { step = max(0, modes.count - 1) }
        persistModes()
    }

    /// Move the slot with `id` by `direction` (-1 or +1). Clamps at both ends.
    /// Slot 0 (locked Raw) cannot be moved and cannot be displaced.
    func move(id: UUID, by direction: Int) {
        guard let i = modes.firstIndex(where: { $0.id == id }) else { return }
        let j = i + direction
        guard modes.indices.contains(j) else { return }
        // Never move slot 0 itself, never push slot 0 out of position 0.
        guard i != 0, j != 0 else { return }
        modes.swapAt(i, j)
        if step == i { step = j }
        else if step == j { step = i }
        persistModes()
    }

    // MARK: - Settings page

    func setSourceLanguage(_ code: String) {
        let next = LanguageCatalog.language(for: code)
        sourceLanguage = next
        UserDefaults.standard.set(next.code, forKey: Preferences.Key.sourceLanguageCode)
        reconcileTargets()
        persistModes()
    }

    // MARK: - Persistence

    private func persistModes() {
        guard let data = try? JSONEncoder().encode(modes) else { return }
        UserDefaults.standard.set(data, forKey: Preferences.Key.modesReel)
    }

    /// Ensure every Translate slot has a target that differs from the current
    /// source language. Slots whose target collides with the source get
    /// swapped to the first catalog entry that isn't the source.
    private func reconcileTargets() {
        let fallback = LanguageCatalog.all.first(where: { $0.code != sourceLanguage.code })?.code ?? "en"
        for i in modes.indices where modes[i].type == .translate {
            let current = modes[i].targetCode ?? fallback
            if current == sourceLanguage.code {
                modes[i].targetCode = fallback
            } else {
                modes[i].targetCode = current
            }
        }
    }
}
