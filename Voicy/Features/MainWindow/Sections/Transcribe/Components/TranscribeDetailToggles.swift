import SwiftUI

struct TranscribeDetailToggles: View {
    @Binding var continuous: Bool
    @Binding var showSpeakers: Bool
    @Binding var showTime: Bool
    @Binding var showPunctuation: Bool
    /// `false` when the underlying entry has no speaker data (model not
    /// installed when it was transcribed, or pre-diarization legacy entry).
    /// The toggle is disabled in that case — flipping it would do nothing.
    let speakersAvailable: Bool

    var body: some View {
        HStack(spacing: 16) {
            chip(label: "Continuous text", isOn: continuous, disabled: false, badge: nil) {
                continuous.toggle()
            }
            chip(
                label: "Speaker labels",
                isOn: showSpeakers,
                disabled: !speakersAvailable,
                badge: speakersAvailable ? nil : "nicht verfügbar"
            ) {
                showSpeakers.toggle()
            }
            chip(label: "Timestamps", isOn: showTime, disabled: continuous, badge: nil) {
                showTime.toggle()
            }
            chip(label: "Smart punctuation", isOn: showPunctuation, disabled: false, badge: nil) {
                showPunctuation.toggle()
            }
        }
    }

    @ViewBuilder
    private func chip(label: String, isOn: Bool, disabled: Bool, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                switchTrack(isOn: isOn)
                Text(label)
                    .font(DS.Font.sans(12, weight: .medium))
                    .foregroundStyle(DS.Palette.ink)
                if let badge {
                    TranscribePhaseBadge(label: badge)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DS.Palette.paperCard, in: Capsule())
            .overlay(Capsule().stroke(DS.Palette.ruleSoft, lineWidth: 1))
            .opacity(disabled ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? Text("on") : Text("off"))
    }

    @ViewBuilder
    private func switchTrack(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? DS.Palette.accent : DS.Palette.ink.opacity(0.18))
                .frame(width: 26, height: 14)
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.15), radius: 0.5, x: 0, y: 0.5)
        }
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}
