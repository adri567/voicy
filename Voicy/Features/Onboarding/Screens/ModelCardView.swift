import SwiftUI

struct ModelCardView: View {
    let model: OnboardingModel
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
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            (Text(model.family + " ")
                                .font(DS.Font.serif(24, weight: .medium))
                             + Text(model.label)
                                .font(DS.Font.serifItalic(24, weight: .medium)))
                                .foregroundStyle(DS.Palette.ink)
                            Text(model.displaySize)
                                .font(DS.Font.mono(9))
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(DS.Palette.ink3)
                        }

                        Text(model.body)
                            .font(DS.Font.sans(13))
                            .lineSpacing(3)
                            .foregroundStyle(DS.Palette.ink2)

                        HStack(spacing: 14) {
                            SpecBlock(label: "Word error", value: model.wer)
                            SpecBlock(label: "Speed", value: model.speed)
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
                        Text(pct >= 100 ? "Ready" : "\(Int(pct))% of \(model.displaySize)")
                    }
                    .font(DS.Font.mono(10))
                    .foregroundStyle(DS.Palette.ink3)
                }
                if let errorText {
                    Text(errorText)
                        .font(DS.Font.mono(10))
                        .foregroundStyle(DS.Palette.accent)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(picked ? DS.Palette.paper : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(picked ? DS.Palette.ink : DS.Palette.ruleSoft, lineWidth: 1)
            )
            .shadow(color: .black.opacity(picked ? 0.08 : 0), radius: 18, y: 6)
            .overlay(alignment: .topTrailing) {
                if model.recommended {
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
                Circle()
                    .fill(DS.Palette.accent)
                    .frame(width: 9, height: 9)
            }
        }
        .padding(.top, 4)
    }
}
