import SwiftUI

struct AudioCaptureView: View {
    @State private var viewModel = AudioCaptureViewModel()

    var body: some View {
        VStack(spacing: 24) {
            header
            recordingStatus
            captureControls
            capturedBufferSummary
            Spacer()
        }
        .padding(24)
        .navigationTitle("Capture")
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.isRecording ? "waveform.circle.fill" : "mic.circle")
                .font(.system(size: 56))
                .foregroundStyle(viewModel.isRecording ? .red : .blue)

            Text("Record a vocal idea")
                .font(.title2.weight(.semibold))

            Text("Capture humming or singing so Topliner can turn it into pitch events in the next stage.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var recordingStatus: some View {
        VStack(spacing: 8) {
            Label(statusText, systemImage: statusIcon)
                .font(.headline)
                .foregroundStyle(statusColor)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var captureControls: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.toggleRecording()
            } label: {
                Label(viewModel.isRecording ? "Stop Recording" : "Record", systemImage: viewModel.isRecording ? "stop.fill" : "record.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isRecording ? .red : .blue)
            .controlSize(.large)

            Button("Request Microphone Permission") {
                viewModel.requestPermission()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isRecording)
        }
    }

    @ViewBuilder
    private var capturedBufferSummary: some View {
        if let buffer = viewModel.capturedBuffer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Captured buffer")
                    .font(.headline)

                Text("\(buffer.samples.count) samples at \(Int(buffer.sampleRate)) Hz")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            Text("No audio captured yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        if viewModel.isRecording { return "Recording" }

        switch viewModel.permissionStatus {
        case .unknown:
            return "Microphone permission not requested"
        case .granted:
            return "Ready to record"
        case .denied:
            return "Microphone permission denied"
        }
    }

    private var statusIcon: String {
        if viewModel.isRecording { return "waveform" }

        switch viewModel.permissionStatus {
        case .unknown:
            return "questionmark.circle"
        case .granted:
            return "checkmark.circle"
        case .denied:
            return "exclamationmark.triangle"
        }
    }

    private var statusColor: Color {
        if viewModel.isRecording { return .red }

        switch viewModel.permissionStatus {
        case .unknown:
            return .secondary
        case .granted:
            return .green
        case .denied:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        AudioCaptureView()
    }
}
