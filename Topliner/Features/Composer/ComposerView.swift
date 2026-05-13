import SwiftUI

struct ComposerView: View {
    @State private var viewModel: ComposerViewModel
    @State private var chordGenerationViewModel: ChordGenerationViewModel
    @State private var playbackController: ComposerPlaybackController
    @State private var isShowingClearConfirmation = false
    @State private var lastPlaybackTick: Date?

    private let playbackTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    init() {
        let voiceManager = AudioKitWavetableVoiceManager()
        let synthService = WavetableSynthService(voice: voiceManager)
        let audioEngine = AudioEngineService(engine: AudioKitEngineManager(inputs: [voiceManager.outputNode]))

        _viewModel = State(initialValue: ComposerViewModel(leadVoice: Self.sampleLeadVoice))
        _chordGenerationViewModel = State(initialValue: ChordGenerationViewModel())
        _playbackController = State(
            initialValue: ComposerPlaybackController(
                audioEngine: audioEngine,
                playback: synthService,
                bpm: 120,
                totalBeats: 16
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            editingControls
            ChordGenerationView(
                viewModel: chordGenerationViewModel,
                melodyNotes: viewModel.leadVoice.notes,
                key: "C",
                bpm: playbackController.bpm,
                totalBeats: playbackController.totalBeats
            )
            MIDIExportShareView(
                leadNotes: viewModel.leadVoice.notes,
                chordProgression: chordGenerationViewModel.generatedProgression,
                bpm: playbackController.bpm
            )

            PianoRollView(
                notes: viewModel.leadVoice.notes,
                selectedNoteID: viewModel.selectedNoteID,
                quantizeGrid: viewModel.leadVoice.quantizeGrid,
                currentBeat: playbackController.currentBeat,
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
        .onReceive(playbackTimer) { tickDate in
            advancePlaybackIfNeeded(at: tickDate)
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
            playbackStatus

            Spacer()

            Button("Delete") {
                viewModel.deleteSelectedNote()
            }
            .disabled(viewModel.selectedNoteID == nil)
            .buttonStyle(.bordered)
            .tint(.red)

            Button(playbackController.isPlaying ? "Stop" : "Play") {
                togglePlayback()
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            Button("Reset") {
                playbackController.reset()
                lastPlaybackTick = nil
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

    private func togglePlayback() {
        if playbackController.isPlaying {
            playbackController.stop()
            lastPlaybackTick = nil
        } else {
            do {
                playbackController.bpm = 120
                playbackController.totalBeats = 16
                try playbackController.start(
                    leadNotes: viewModel.leadVoice.notes,
                    chordProgression: chordGenerationViewModel.generatedProgression
                )
                lastPlaybackTick = Date()
            } catch {
                lastPlaybackTick = nil
            }
        }
    }

    private func advancePlaybackIfNeeded(at tickDate: Date) {
        guard playbackController.isPlaying else {
            lastPlaybackTick = nil
            return
        }

        guard let lastPlaybackTick else {
            self.lastPlaybackTick = tickDate
            return
        }

        playbackController.advance(elapsedSeconds: tickDate.timeIntervalSince(lastPlaybackTick))
        self.lastPlaybackTick = tickDate
    }

    @ViewBuilder
    private var playbackStatus: some View {
        if let errorMessage = playbackController.lastErrorMessage {
            Text("Playback error: \(errorMessage)")
                .font(.caption)
                .foregroundStyle(.red.opacity(0.9))
        } else if playbackController.isPlaying {
            Text("Playing local synth")
                .font(.caption)
                .foregroundStyle(.cyan.opacity(0.85))
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
