import SwiftUI

struct LLMRow: View {
    let model: LLMModel
    let index: Int
    let first: Bool
    let status: BrainViewModel.Status?
    let onInstall: () -> Void
    let onSetDefault: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if !first {
                SoftDivider()
            }
            HStack(alignment: .top, spacing: 28) {
                Text(String(format: "%02d", index))
                    .font(DS.Font.serifItalic(36))
                    .foregroundStyle(status == .active ? DS.Palette.accent : DS.Palette.ink3)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(model.name)
                            .font(DS.Font.serif(26))
                            .tracking(-0.3)
                            .foregroundStyle(DS.Palette.ink)
                        MetaLabel(text: model.family)
                        LocationChip(location: model.location)
                    }
                    Text(model.description)
                        .font(DS.Font.sans(14))
                        .lineSpacing(2)
                        .foregroundStyle(DS.Palette.ink2)
                        .frame(maxWidth: 560, alignment: .leading)
                    if let h = model.highlight {
                        Text("★ \(h)")
                            .font(DS.Font.mono(9))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(DS.Palette.accent)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    specRow(label: "size",    value: model.size)
                    specRow(label: "context", value: model.context)
                    specRow(label: "speed",   value: model.speed)
                    specRow(label: "quality", value: nil, quality: model.quality)
                }
                .frame(width: 200)

                actionBlock
                    .frame(width: 160, alignment: .trailing)
            }
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var actionBlock: some View {
        VStack(alignment: .trailing, spacing: 10) {
            badge

            if model.location == .cloud {
                cloudComingSoon
            } else if let status {
                liveActionBlock(status: status)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func liveActionBlock(status: BrainViewModel.Status) -> some View {
        switch status {
        case .active:
            MetaLabel(text: "Loaded in RAM")
            TrashButton(onTap: onRemove)
        case .installed:
            Button("Set as default", action: onSetDefault)
                .buttonStyle(.plain)
                .font(DS.Font.sans(11, weight: .medium))
                .foregroundStyle(DS.Palette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(DS.Palette.ink, lineWidth: 1))
            TrashButton(onTap: onRemove)
        case .downloading(let fraction):
            ProgressBar(fraction: fraction)
                .frame(width: 140)
        case .notInstalled:
            Button(action: onInstall) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("Install")
                        .font(DS.Font.sans(11, weight: .semibold))
                }
                .foregroundStyle(DS.Palette.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DS.Palette.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var cloudComingSoon: some View {
        Button("Notify me") {
            // TODO(brain-notify): cloud-model opt-in flow not implemented
        }
        .buttonStyle(.plain)
        .font(DS.Font.sans(11, weight: .medium))
        .foregroundStyle(DS.Palette.ink3)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .overlay(
            Capsule().strokeBorder(
                DS.Palette.ruleSoft,
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        )
    }

    private var badge: some View {
        let tuple: (String, Bool, Bool) = {
            if model.location == .cloud {
                return ("Coming soon", false, false)
            }
            switch status {
            case .active:        return ("In use",      false, true)
            case .installed:     return ("Installed",   false, false)
            case .downloading:   return ("Downloading", true,  false)
            case .notInstalled:  return ("Available",   false, false)
            case .none:          return ("Available",   false, false)
            }
        }()
        return Text(tuple.0).dsTag(solid: tuple.1, accent: tuple.2)
    }

    private func specRow(label: String, value: String?, quality: Double? = nil) -> some View {
        HStack {
            MetaLabel(text: label)
            Spacer()
            if let value {
                Text(value).font(DS.Font.mono(11)).foregroundStyle(DS.Palette.ink)
            } else if let quality {
                HStack(spacing: 8) {
                    Text("\(Int(quality * 100))%")
                        .font(DS.Font.mono(11))
                        .foregroundStyle(DS.Palette.ink)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.1)).frame(height: 4)
                            Capsule().fill(DS.Palette.ink).frame(width: geo.size.width * quality, height: 4)
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            }
        }
    }
}
