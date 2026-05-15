import AppKit
import SwiftUI

struct MenuBarStatusView: View {

    var viewModel: RecordingViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Voicy")
                    .font(.headline)

                statusIndicator

                if let progress = viewModel.correctionModelProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(progress > 0
                             ? String(format: "KI-Modell: %.0f %%", progress * 100)
                             : "KI-Modell wird geladen…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: progress > 0 ? progress : nil)
                            .tint(.blue)
                    }
                }

                if viewModel.state != .loadingModel {
                    Text("Fn gedrückt halten")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)

            Divider()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: MainWindowID.id)
            } label: {
                Label("Voicy öffnen…", systemImage: "macwindow")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Button("Beenden") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 220)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch viewModel.state {
        case .loadingModel:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 14, height: 14)
                Text("Modell wird geladen…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .idle:
            statusRow(color: .green, label: "Bereit")
        case .recording:
            statusRow(color: .red, label: "Aufnahme läuft…")
        case .transcribing:
            statusRow(color: .orange, label: "Transkribiere…")
        case .correcting:
            statusRow(color: .orange, label: "Korrigiere…")
        case .noModel:
            statusRow(color: .yellow, label: "Kein Voice-Modell installiert")
        case .noBrain:
            statusRow(color: .yellow, label: "Kein KI-Modell installiert")
        }
    }

    private func statusRow(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
        }
    }
}
