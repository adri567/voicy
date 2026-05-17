import AppKit
import SwiftUI

struct MenuBarStatusView: View {

    var viewModel: RecordingViewModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage(Preferences.Key.onboardingCompleted) private var onboardingCompleted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if onboardingCompleted {
                readyContent
            } else {
                onboardingPendingContent
            }
        }
        .frame(width: 220)
    }

    @ViewBuilder
    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voicy")
                .font(.headline)

            statusIndicator

            if let progress = viewModel.correctionModelProgress {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress > 0
                         ? String(format: "AI model: %.0f %%", progress * 100)
                         : "Loading AI model…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: progress > 0 ? progress : nil)
                        .tint(.blue)
                }
            }

            if viewModel.state != .loadingModel {
                Text("Hold Fn")
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
            Label("Open Voicy…", systemImage: "macwindow")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var onboardingPendingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voicy")
                .font(.headline)

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                Text("Onboarding pending")
                    .font(.subheadline)
            }

            Text("Finish setup to start using Voicy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)

        Divider()

        Button {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: OnboardingWindowID.id)
        } label: {
            Label("Resume onboarding", systemImage: "arrow.right.circle")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch viewModel.state {
        case .loadingModel:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 14, height: 14)
                Text("Loading model…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .idle:
            statusRow(color: .green, label: "Ready")
        case .recording:
            statusRow(color: .red, label: "Recording…")
        case .transcribing:
            statusRow(color: .orange, label: "Transcribing…")
        case .correcting:
            statusRow(color: .orange, label: "Polishing…")
        case .noModel:
            statusRow(color: .yellow, label: "No voice model installed")
        case .noBrain:
            statusRow(color: .yellow, label: "No AI model installed")
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
