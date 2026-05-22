import AppKit
import FactoryKit
import Foundation
import Observation

@Observable @MainActor final class MicrophoneSelectorViewModel {

    @ObservationIgnored @Injected(\.audioInputDeviceService) private var service

    var devices: [AudioInputDevice] = []
    var selectedUID: String?
    var isOpen: Bool = false

    private var observeTask: Task<Void, Never>?

    init() {
        self.selectedUID = UserDefaults.standard.string(forKey: Preferences.Key.selectedAudioDeviceUID)
    }

    func start() {
        observeTask?.cancel()
        let stream = service.changes
        observeTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else { return }
                await MainActor.run { self.devices = snapshot }
            }
        }
        // Prime an initial snapshot in case the listener hasn't fired yet.
        Task { [weak self] in
            guard let self else { return }
            let initial = await self.service.currentSnapshot()
            await MainActor.run {
                if self.devices.isEmpty { self.devices = initial }
            }
        }
    }

    var current: AudioInputDevice? {
        guard let selectedUID, !selectedUID.isEmpty else { return nil }
        return devices.first { $0.uid == selectedUID }
    }

    var isFollowingSystemDefault: Bool {
        selectedUID == nil || selectedUID?.isEmpty == true
    }

    func select(_ device: AudioInputDevice) {
        selectedUID = device.uid
        UserDefaults.standard.set(device.uid, forKey: Preferences.Key.selectedAudioDeviceUID)
        isOpen = false
    }

    func selectSystemDefault() {
        selectedUID = nil
        UserDefaults.standard.removeObject(forKey: Preferences.Key.selectedAudioDeviceUID)
        isOpen = false
    }

    func openSoundSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")
            ?? URL(string: "x-apple.systempreferences:com.apple.preference.sound")!
        NSWorkspace.shared.open(url)
    }
}
