import SwiftUI

struct AudioCaptureView: View {
    @State private var viewModel = AudioCaptureViewModel()

    var body: some View {
        VStack(spacing: 24) {
            header
            recordingStatus
            captureControls
            capturedBufferSummary
            pitchRollPreview
            pitchTraceSummary
            draftMIDINotesSummary
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

    @ViewBuilder
    private var pitchRollPreview: some View {
        let ghostTrace = viewModel.isRecording ? viewModel.pitchTrace : []
        let renderedNotes = viewModel.isRecording ? [] : viewModel.draftMIDINotes

        if !ghostTrace.isEmpty || !renderedNotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.isRecording ? "Live pitch trace" : "Quantized capture")
                    .font(.headline)

                PianoRollView(
                    notes: renderedNotes,
                    selectedNoteID: nil,
                    totalBeats: 16,
                    pitchRange: 48...84,
                    currentBeat: nil,
                    pitchTrace: ghostTrace,
                    bpm: 120
                )
                .frame(height: 220)
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var pitchTraceSummary: some View {
        if !viewModel.pitchTrace.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pitch trace")
                    .font(.headline)

                Text("\(viewModel.pitchTrace.count) pitch samples detected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let firstPitch = viewModel.pitchTrace.first?.midiNote,
                   let lastPitch = viewModel.pitchTrace.last?.midiNote {
                    Text("MIDI \(firstPitch) → \(lastPitch)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        } else if viewModel.capturedBuffer != nil {
            Text("No confident pitch samples detected yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var draftMIDINotesSummary: some View {
        if !viewModel.draftMIDINotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Draft MIDI notes")
                    .font(.headline)

                Text("\(viewModel.draftMIDINotes.count) notes segmented and quantized")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let firstNote = viewModel.draftMIDINotes.first,
                   let lastNote = viewModel.draftMIDINotes.last {
                    Text("MIDI \(firstNote.pitch) at beat \(formattedBeat(firstNote.startBeat)) → MIDI \(lastNote.pitch)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        } else if !viewModel.pitchTrace.isEmpty {
            Text("No draft MIDI notes survived segmentation yet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedBeat(_ beat: Double) -> String {
        beat.formatted(.number.precision(.fractionLength(0...2)))
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
