import SwiftUI

struct AudioDeviceKindIcon: View {
    let kind: AudioInputDeviceKind
    var size: CGFloat = 10

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size, weight: .medium))
    }

    private var symbolName: String {
        switch kind {
        case .builtIn:  "laptopcomputer"
        case .wireless: "wave.3.right.circle"
        case .usb:      "cable.connector"
        case .external: "display"
        case .virtual:  "waveform"
        }
    }
}
