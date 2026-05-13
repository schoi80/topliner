import SwiftUI

struct ComposerView: View {
    @State private var viewModel = ComposerViewModel(leadVoice: Self.sampleLeadVoice)
    @State private var chordGenerationViewModel = ChordGenerationViewModel()
    @State private var playheadController = PlayheadController(bpm: 120, totalBeats: 16)
    @State private var isShowingClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            editingControls
            ChordGenerationView(
                viewModel: chordGenerationViewModel,
                melodyNotes: viewModel.leadVoice.notes,
                key: "C",
                bpm: playheadController.bpm,
                totalBeats: playheadController.totalBeats
            )
            MIDIExportShareView(
                leadNotes: viewModel.leadVoice.notes,
                chordProgression: chordGenerationViewModel.generatedProgression,
                bpm: playheadController.bpm
            )

            PianoRollView(
                notes: viewModel.leadVoice.notes,
                selectedNoteID: viewModel.selectedNoteID,
                quantizeGrid: viewModel.leadVoice.quantizeGrid,
                currentBeat: playheadController.currentBeat,
                onTap: viewModel.handlePianoRollTap,
                onDrag: viewModel.handlePianoRollDrag,
                onResize: viewModel.handlePianoRollResize
            )
            .frame(minHeight: 320)
        }
        .padding(20)
        .background(Color(red: 0.025, green: 0.028, blue: 0.038))
        .alert("Clear lead notes?", isPresented: $isShowingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearLeadNotes()
            }
        } message: {
            Text("This removes every note from the piano roll.")
        }
    }

    private static var sampleLeadVoice: LeadVoiceBuffer {
        LeadVoiceBuffer(
            notes: [
                MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
                MIDINoteEvent(pitch: 62, startBeat: 1, durationBeats: 1, velocity: 100),
                MIDINoteEvent(pitch: 64, startBeat: 2, durationBeats: 1, velocity: 100),
                MIDINoteEvent(pitch: 67, startBeat: 3, durationBeats: 2, velocity: 100),
                MIDINoteEvent(pitch: 69, startBeat: 6, durationBeats: 1.5, velocity: 100)
            ],
            source: .pianoRoll,
            quantizeGrid: 0.25
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Topliner")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Draw or hum a melody, then generate harmony.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var editingControls: some View {
        HStack(spacing: 12) {
            selectionStatus

            Spacer()

            Button("Delete") {
                viewModel.deleteSelectedNote()
            }
            .disabled(viewModel.selectedNoteID == nil)
            .buttonStyle(.bordered)
            .tint(.red)

            Button(playheadController.isPlaying ? "Stop" : "Play") {
                if playheadController.isPlaying {
                    playheadController.stop()
                } else {
                    playheadController.start()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            Button("Reset") {
                playheadController.reset()
            }
            .buttonStyle(.bordered)
            .tint(.cyan)

            Button("Clear") {
                isShowingClearConfirmation = true
            }
            .disabled(viewModel.leadVoice.notes.isEmpty)
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    private var selectionStatus: some View {
        if let selectedNote = viewModel.leadVoice.notes.first(where: { $0.id == viewModel.selectedNoteID }) {
            Text("Selected: MIDI \(selectedNote.pitch) · beat \(selectedNote.startBeat, specifier: "%.2f") · \(selectedNote.durationBeats, specifier: "%.2f") beats")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.78))
        } else {
            Text("No note selected")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

#Preview {
    ComposerView()
}
