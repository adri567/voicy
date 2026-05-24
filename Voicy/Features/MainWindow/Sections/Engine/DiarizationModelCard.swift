import FactoryKit
import OSLog
import SwiftUI

/// Installable add-on for speaker diarization (Sortformer). Not part of the
/// transcription engine library — there's no "set as default" because it
/// always runs in parallel to whichever engine is active, when installed.
struct DiarizationModelCard: View {

    @State private var status: Status
    @State private var task: Task<Void, Never>?

    @Injected(\.diarizationService) private var service

    init() {
        _status = State(
            initialValue: FluidAudioDiarizationService.isInstalled(
                variant: FluidAudioDiarizationService.activeVariant,
                stepSize: FluidAudioDiarizationService.activeStepSize
            )
                ? .installed
                : .notInstalled
        )
    }

    enum Status: Equatable {
        case notInstalled
        case downloading(DownloadPhase)
        case installed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading
                .padding(.bottom, 18)
            HStack(alignment: .top, spacing: 28) {
                description
                    .frame(maxWidth: .infinity, alignment: .leading)
                specs
                    .frame(width: 200)
                action
                    .frame(width: 160, alignment: .trailing)
            }
        }
        .padding(28)
        .dsPanel()
    }

    @ViewBuilder
    private var heading: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                MetaLabel(text: "◆ Add-on", color: DS.Palette.accent)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Speaker recognition")
                        .font(DS.Font.serif(26))
                        .tracking(-0.3)
                        .foregroundStyle(DS.Palette.ink)
                    Text("Beta").dsTag()
                }
            }
            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        let label: String = {
            switch status {
            case .notInstalled: return "Available"
            case .downloading:  return "Downloading"
            case .installed:    return "Installed"
            }
        }()
        let isDownloading: Bool = {
            if case .downloading = status { return true }
            return false
        }()
        return Text(label).dsTag(solid: isDownloading)
    }

    @ViewBuilder
    private var description: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sortformer (NVIDIA · FluidAudio)")
                .font(DS.Font.mono(10, weight: .medium))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(DS.Palette.ink2)
            Text("Automatically detects who's speaking. Runs in parallel with transcription. 4 speaker slots, on-device, ~50 MB.")
                .font(DS.Font.sans(14))
                .lineSpacing(2)
                .foregroundStyle(DS.Palette.ink2)
        }
    }

    @ViewBuilder
    private var specs: some View {
        VStack(alignment: .leading, spacing: 6) {
            specRow(label: "size",     value: "~50 MB")
            specRow(label: "speakers", value: "up to 4")
            specRow(label: "engine",   value: "any")
        }
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            MetaLabel(text: label)
            Spacer()
            Text(value)
                .font(DS.Font.mono(11))
                .foregroundStyle(DS.Palette.ink)
        }
    }

    @ViewBuilder
    private var action: some View {
        switch status {
        case .notInstalled:
            installButton
        case .downloading(let phase):
            ProgressBar(phase: phase)
                .frame(width: 140)
        case .installed:
            VStack(alignment: .trailing, spacing: 10) {
                MetaLabel(text: "Ready")
                TrashButton(onTap: remove)
            }
        }
    }

    private var installButton: some View {
        Button(action: install) {
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

    // MARK: - Actions

    private func install() {
        guard case .notInstalled = status else { return }
        Log.diarization.debug("Sortformer: install tapped")
        status = .downloading(.preparing)
        task?.cancel()
        task = Task { [service] in
            do {
                try await service.installModel { phase in
                    // progress closure can fire on any executor — hop to main
                    // before touching SwiftUI state.
                    Task { @MainActor in
                        guard case .downloading(let current) = status else { return }
                        status = .downloading(current.advanced(to: phase))
                    }
                }
                await MainActor.run { status = .installed }
                Log.diarization.debug("Sortformer: install complete")
            } catch {
                Log.diarization.error("Sortformer: install failed: \(error.localizedDescription, privacy: .public)")
                await MainActor.run { status = .notInstalled }
            }
        }
    }

    private func remove() {
        task?.cancel()
        task = Task { @MainActor [service] in
            do {
                try await service.removeModel()
                status = .notInstalled
            } catch {
                Log.diarization.error("Sortformer: remove failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
