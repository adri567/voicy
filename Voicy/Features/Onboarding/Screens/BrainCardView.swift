import SwiftUI

struct BrainCardView: View {
    let brain: OnboardingBrain
    let picked: Bool
    let dlPct: Double?
    let errorText: String?
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    radio
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            (Text(brain.name + " ")
                                .font(DS.Font.serif(22, weight: .medium))
                             + Text(brain.variant)
                                .font(DS.Font.serifItalic(22, weight: .medium)))
                                .foregroundStyle(DS.Palette.ink)
                            Text(brain.family)
                                .font(DS.Font.mono(9))
                                .tracking(1.2)
                                .foregroundStyle(DS.Palette.ink3)
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
                    if let pct = dlPct, pct >= 100 {
                        Text("● READY")
                            .font(DS.Font.mono(9))
                            .tracking(1.0)
                            .foregroundStyle(DS.Palette.accentInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DS.Palette.accent2, in: Capsule())
                    }
                }
                if let pct = dlPct, pct > 0 {
                    OnboardingProgressBar(value: pct)
                    HStack {
                        Text(pct >= 100 ? "Downloaded · verified" : "Downloading · \(Int(pct))%")
                        Spacer()
                        Text(pct >= 100 ? "SHA-256 ✓" : "\(Int(pct))% of \(brain.size)")
                    }
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                }
                if let errorText {
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
