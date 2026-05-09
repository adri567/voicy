import SwiftUI

struct RecordingView: View {

    var viewModel: RecordingViewModel

    var body: some View {
        VStack(spacing: 16) {
            statusView
            recordButton
            if !viewModel.transcript.isEmpty {
                transcriptView
            }
        }
        .padding(20)
        .frame(width: 320)
        .task { await viewModel.onAppear() }
    }

    @ViewBuilder
    private var statusView: some View {
        switch viewModel.state {
        case .loadingModel:
            VStack(spacing: 8) {
                ProgressView()
                Text("Modell wird geladen…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .transcribing:
            VStack(spacing: 8) {
                ProgressView()
                Text("Transkribiere…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .idle, .recording:
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var recordButton: some View {
        Button {
            Task { await viewModel.toggleRecording() }
        } label: {
            Image(systemName: recordButtonIcon)
                .font(.system(size: 36))
                .symbolEffect(.pulse, isActive: viewModel.state == .recording)
                .foregroundStyle(recordButtonColor)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state == .loadingModel || viewModel.state == .transcribing)
    }

    private var transcriptView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            ScrollView {
                Text(viewModel.transcript)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 120)
            Button("Kopieren") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(viewModel.transcript, forType: .string)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var recordButtonIcon: String {
        switch viewModel.state {
        case .recording: "stop.circle.fill"
        default: "mic.circle.fill"
        }
    }

    private var recordButtonColor: Color {
        switch viewModel.state {
        case .recording: .red
        case .loadingModel, .transcribing: .secondary
        default: .accentColor
        }
    }
}
