import SwiftUI

struct AudioCaptureView: View {
    @State private var viewModel = AudioCaptureViewModel()

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: StudioLayout.panelSpacing) {
                captureTransport

                HStack(spacing: StudioLayout.panelSpacing) {
                    captureLane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    takesPanel
                        .frame(width: min(StudioLayout.harmonyPanelWidth, max(260, proxy.size.width * 0.30)))
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(StudioLayout.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(StudioTheme.background.ignoresSafeArea())
        }
        .navigationTitle("Capture")
    }

    private var captureTransport: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Capture Takes")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
                Label(statusText, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            Spacer(minLength: 12)

            Stepper(value: $viewModel.bpm, in: 40...240, step: 1) {
                StudioControlChip(title: "BPM", value: "\(Int(viewModel.bpm))", systemImage: "metronome", isActive: true, tint: StudioTheme.orange)
            }
            .labelsHidden()
            .frame(maxWidth: 170)

            Stepper(value: $viewModel.countInBars, in: 0...4, step: 1) {
                StudioControlChip(title: "Count-in", value: "\(viewModel.countInBars)b", systemImage: "timer", isActive: viewModel.countInBars > 0, tint: StudioTheme.violet)
            }
            .labelsHidden()
            .frame(maxWidth: 170)

            Button {
                viewModel.isMetronomeEnabled.toggle()
            } label: {
                StudioControlChip(title: "Click", value: viewModel.isMetronomeEnabled ? "On" : "Off", systemImage: "speaker.wave.2", isActive: viewModel.isMetronomeEnabled, tint: StudioTheme.cyan)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.toggleRecording()
            } label: {
                Label(viewModel.isRecording ? "Stop" : "Record", systemImage: viewModel.isRecording ? "stop.fill" : "record.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(minWidth: 118, minHeight: StudioLayout.minimumTouchTarget)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isRecording ? StudioTheme.danger : StudioTheme.orange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
        )
    }

    private var captureLane: some View {
        StudioPanel("Performance Lane", subtitle: "Sing or hum; Topliner converts the take into editable MIDI") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isRecording ? "waveform.circle.fill" : "mic.circle")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(viewModel.isRecording ? StudioTheme.danger : StudioTheme.cyan)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.isRecording ? "Recording live input" : "Ready for a new take")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(StudioTheme.textPrimary)
                        Text("Count-in \(viewModel.countInBars) bars · \(Int(viewModel.bpm)) BPM · click \(viewModel.isMetronomeEnabled ? "enabled" : "muted")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(StudioTheme.textSecondary)
                    }

                    Spacer()

                    Button("Request Mic") {
                        viewModel.requestPermission()
                    }
                    .buttonStyle(.bordered)
                    .tint(StudioTheme.cyan)
                    .disabled(viewModel.isRecording)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StudioTheme.danger)
                        .lineLimit(2)
                }

                PianoRollView(
                    notes: viewModel.isRecording ? [] : viewModel.draftMIDINotes,
                    selectedNoteID: nil,
                    totalBeats: 16,
                    pitchRange: 48...84,
                    currentBeat: nil,
                    pitchTrace: viewModel.isRecording ? viewModel.pitchTrace : [],
                    bpm: viewModel.bpm
                )
                .frame(maxHeight: .infinity)
                .background(StudioTheme.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(StudioTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private var takesPanel: some View {
        StudioPanel("Takes", subtitle: takeSubtitle) {
            VStack(alignment: .leading, spacing: 14) {
                metricRow(title: "Audio", value: capturedBufferText, icon: "waveform")
                metricRow(title: "Pitch", value: "\(viewModel.pitchTrace.count) samples", icon: "point.3.connected.trianglepath.dotted")
                metricRow(title: "MIDI", value: "\(viewModel.draftMIDINotes.count) notes", icon: "pianokeys")

                Divider().overlay(StudioTheme.border)

                if !viewModel.draftMIDINotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest quantized take")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(StudioTheme.textSecondary)
                        ForEach(viewModel.draftMIDINotes.prefix(4)) { note in
                            Text("MIDI \(note.pitch) · beat \(formattedBeat(note.startBeat)) · dur \(formattedBeat(note.durationBeats))")
                                .font(.caption.monospaced())
                                .foregroundStyle(StudioTheme.textPrimary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text("Recorded takes will appear here with pitch trace and quantized MIDI summaries.")
                        .font(.caption)
                        .foregroundStyle(StudioTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    // Composer handoff will wire into project routing in a later persistence slice.
                } label: {
                    Label("Edit in Composer", systemImage: "square.and.pencil")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: StudioLayout.minimumTouchTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(StudioTheme.violet)
                .disabled(viewModel.draftMIDINotes.isEmpty)
            }
        }
    }

    private var takeSubtitle: String {
        viewModel.isRecording ? "Armed and listening" : "Latest capture summary"
    }

    private var capturedBufferText: String {
        guard let buffer = viewModel.capturedBuffer else { return "No take" }
        return "\(buffer.samples.count) @ \(Int(buffer.sampleRate)) Hz"
    }

    private func metricRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(StudioTheme.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(StudioTheme.textMuted)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(StudioTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        if viewModel.isRecording { return StudioTheme.danger }

        switch viewModel.permissionStatus {
        case .unknown:
            return StudioTheme.textMuted
        case .granted:
            return StudioTheme.lime
        case .denied:
            return StudioTheme.danger
        }
    }
}

#Preview {
    AudioCaptureView()
}
