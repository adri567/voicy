import SwiftUI

struct BrainCardView: View {
    let brain: OnboardingBrain
    let picked: Bool
    /// Download state for *this* card, or `nil` if it isn't the selected one.
    let download: DownloadUIState?
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    radio
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(brain.name)
                                .font(DS.Font.serifItalic(22, weight: .medium))
                                .foregroundStyle(DS.Palette.ink)
                            Text(brain.tier).dsTag()
                        }
                        Text(brain.body)
                            .font(DS.Font.sans(13))
                            .lineSpacing(3)
                            .foregroundStyle(DS.Palette.ink2)
                        HStack(spacing: 14) {
                            SpecBlock(label: "Size", value: brain.size)
                            SpecBlock(label: "Context", value: brain.context)
                            SpecBlock(label: "Speed", value: brain.speed)
                            SpecBlock(label: "Quality", value: "\(brain.quality)%")
                        }
                    }
                    Spacer(minLength: 0)
                    if download?.isReady == true {
                        Text("● READY")
                            .font(DS.Font.mono(9))
                            .tracking(1.0)
                            .foregroundStyle(DS.Palette.accentInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DS.Palette.accent2, in: Capsule())
                    }
                }
                if let phase = download?.phase {
                    OnboardingProgressBar(phase: phase)
                    HStack {
                        Text(phase.isIndeterminate ? phase.shortLabel : "Downloading · \(phase.shortLabel)")
                        Spacer()
                        Text(phase.fraction != nil ? "\(phase.shortLabel) of \(brain.size)" : brain.size)
                    }
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                }
                if let errorText = download?.errorText {
                    Text(errorText)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(Color(red: 0.78, green: 0.22, blue: 0.18))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(picked ? DS.Palette.paper : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(picked ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .shadow(color: .black.opacity(picked ? 0.08 : 0), radius: 18, y: 6)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                if brain.recommended {
                    Text("Recommended")
                        .font(DS.Font.mono(9))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(DS.Palette.accentInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DS.Palette.accent, in: Capsule())
                        .offset(x: -18, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var radio: some View {
        ZStack {
            Circle()
                .stroke(picked ? DS.Palette.accent : DS.Palette.ink.opacity(0.25), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            if picked {
                Circle().fill(DS.Palette.accent).frame(width: 9, height: 9)
            }
        }
        .padding(.top, 3)
    }
}
