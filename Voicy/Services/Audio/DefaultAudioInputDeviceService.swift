@preconcurrency import CoreAudio
import Foundation

/// CoreAudio HAL backed enumeration of audio input devices.
///
/// Reads the device list directly from `kAudioObjectSystemObject` and subscribes
/// to hotplug changes via `AudioObjectAddPropertyListenerBlock`. Filters to
/// devices that expose at least one input stream so virtual-only output devices
/// (e.g. external speakers) don't pollute the picker.
actor DefaultAudioInputDeviceService: AudioInputDeviceService {

    // MARK: - AsyncStream plumbing (nonisolated so the protocol's
    // `changes` getter doesn't need a hop into the actor).
    nonisolated let changes: AsyncStream<[AudioInputDevice]>
    private nonisolated let continuation: AsyncStream<[AudioInputDevice]>.Continuation

    private let listenerQueue = DispatchQueue(label: "dev.voicy.audio-device-listener")

    init() {
        let (stream, continuation) = AsyncStream<[AudioInputDevice]>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.changes = stream
        self.continuation = continuation

        Task { await self.installHotplugListener() }
    }

    // MARK: - Protocol

    func currentSnapshot() -> [AudioInputDevice] {
        Self.enumerateInputDevices()
    }

    func deviceID(forUID uid: String) -> AudioDeviceID? {
        Self.enumerateInputDevices().first { $0.uid == uid }?.id
    }

    func systemDefaultDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var id: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &id
        )
        return status == noErr && id != kAudioObjectUnknown ? id : nil
    }

    // MARK: - Hotplug

    private func installHotplugListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let continuation = self.continuation
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            listenerQueue
        ) { _, _ in
            continuation.yield(Self.enumerateInputDevices())
        }
        if status != noErr {
            print("[AudioInputDeviceService] Hotplug listener install failed: \(status)")
        }
        // Emit the initial snapshot so subscribers don't have to call `currentSnapshot`
        // separately.
        continuation.yield(Self.enumerateInputDevices())
    }

    // MARK: - HAL reads (all nonisolated so the listener block can call them)

    private nonisolated static func enumerateInputDevices() -> [AudioInputDevice] {
        deviceIDs()
            .filter { hasInputStreams(deviceID: $0) }
            .compactMap { device(forID: $0) }
    }

    private nonisolated static func deviceIDs() -> [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size
        ) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        guard count > 0 else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: count)
        let status = ids.withUnsafeMutableBufferPointer { buffer -> OSStatus in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address, 0, nil, &size, buffer.baseAddress!
            )
        }
        return status == noErr ? ids : []
    }

    private nonisolated static func hasInputStreams(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        return status == noErr && size > 0
    }

    private nonisolated static func device(forID id: AudioDeviceID) -> AudioInputDevice? {
        guard let uid = stringProperty(id: id, selector: kAudioDevicePropertyDeviceUID),
              let name = stringProperty(id: id, selector: kAudioObjectPropertyName)
        else { return nil }
        let transport = uint32Property(
            id: id,
            selector: kAudioDevicePropertyTransportType,
            scope: kAudioObjectPropertyScopeGlobal
        )
        let kind = kind(forTransport: transport)
        let sampleRate = doubleProperty(
            id: id,
            selector: kAudioDevicePropertyNominalSampleRate,
            scope: kAudioObjectPropertyScopeInput
        )
        let subtitle = subtitle(forKind: kind, sampleRate: sampleRate)
        return AudioInputDevice(id: id, uid: uid, name: name, subtitle: subtitle, kind: kind)
    }

    // MARK: - Property helpers

    private nonisolated static func stringProperty(
        id: AudioDeviceID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfString: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &cfString) { ptr -> OSStatus in
            AudioObjectGetPropertyData(id, &address, 0, nil, &size, ptr)
        }
        guard status == noErr else { return nil }
        return cfString as String
    }

    private nonisolated static func uint32Property(
        id: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    private nonisolated static func doubleProperty(
        id: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> Double? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Double = 0
        var size = UInt32(MemoryLayout<Double>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    // MARK: - Mapping

    private nonisolated static func kind(forTransport transport: UInt32?) -> AudioInputDeviceKind {
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtIn
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE, kAudioDeviceTransportTypeAirPlay:
            return .wireless
        case kAudioDeviceTransportTypeUSB:
            return .usb
        case kAudioDeviceTransportTypeThunderbolt, kAudioDeviceTransportTypeDisplayPort, kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeFireWire, kAudioDeviceTransportTypePCI:
            return .external
        case kAudioDeviceTransportTypeAggregate, kAudioDeviceTransportTypeVirtual, kAudioDeviceTransportTypeAutoAggregate, kAudioDeviceTransportTypeContinuityCaptureWired, kAudioDeviceTransportTypeContinuityCaptureWireless:
            return .virtual
        default:
            return .external
        }
    }

    private nonisolated static func subtitle(forKind kind: AudioInputDeviceKind, sampleRate: Double?) -> String {
        let transportLabel: String = switch kind {
        case .builtIn:  "Built-in"
        case .wireless: "Bluetooth"
        case .usb:      "USB"
        case .external: "External"
        case .virtual:  "Virtual"
        }
        guard let sampleRate, sampleRate > 0 else { return transportLabel }
        let kHz = sampleRate / 1000
        let formatted: String
        if kHz == floor(kHz) {
            formatted = "\(Int(kHz)) kHz"
        } else {
            formatted = String(format: "%.1f kHz", kHz)
        }
        return "\(transportLabel) · \(formatted)"
    }
}
