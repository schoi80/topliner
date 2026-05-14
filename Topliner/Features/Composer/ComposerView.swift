import AudioKit
import SwiftUI

struct ComposerView: View {
    @State private var viewModel: ComposerViewModel
    @State private var chordGenerationViewModel: ChordGenerationViewModel
    @State private var playbackController: ComposerPlaybackController
    @State private var isShowingClearConfirmation = false
    @State private var lastPlaybackTick: Date?

    private let playbackTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    init() {
        let leadVoiceManager = AudioKitWavetableVoiceManager(waveform: Table(.sine))
        let chordVoiceManager = AudioKitWavetableVoiceManager(waveform: Table(.triangle))
        let leadSynthService = WavetableSynthService(voice: leadVoiceManager)
        let chordSynthService = WavetableSynthService(
            voice: chordVoiceManager,
            envelope: SynthEnvelope(attackDuration: 0.015, decayDuration: 0.28, sustainLevel: 0.55, releaseDuration: 0.45)
        )
        let audioEngine = AudioEngineService(engine: AudioKitEngineManager(inputs: [leadVoiceManager.outputNode, chordVoiceManager.outputNode]))

        _viewModel = State(initialValue: ComposerViewModel(leadVoice: Self.sampleLeadVoice))
        _chordGenerationViewModel = State(initialValue: ChordGenerationViewModel())
        _playbackController = State(
            initialValue: ComposerPlaybackController(
                audioEngine: audioEngine,
                leadPlayback: leadSynthService,
                chordPlayback: chordSynthService,
                bpm: 120,
                totalBeats: 16
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: StudioLayout.panelSpacing) {
                ComposerTransportView(
                    projectTitle: "Neon Drift",
                    bpm: viewModel.bpm,
                    barLength: viewModel.barLength,
                    isMetronomeEnabled: viewModel.isMetronomeEnabled,
                    quantizeGrid: viewModel.leadVoice.quantizeGrid,
                    isPlaying: playbackController.isPlaying,
                    onReset: resetPlayback,
                    onPlayStop: togglePlayback
                )

                HStack(spacing: StudioLayout.panelSpacing) {
                    pitchStrip

                    PianoRollView(
                        notes: viewModel.leadVoice.notes,
                        chordNotes: chordGenerationViewModel.generatedChordNotes,
                        selectedNoteID: viewModel.selectedNoteID,
                        totalBeats: viewModel.totalBeats,
                        quantizeGrid: viewModel.leadVoice.quantizeGrid,
                        currentBeat: playbackController.currentBeat,
                        bpm: viewModel.bpm,
                        onTap: viewModel.handlePianoRollTap,
                        onDrag: viewModel.handlePianoRollDrag,
                        onResize: viewModel.handlePianoRollResize
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(StudioTheme.border, lineWidth: 1)
                            .allowsHitTesting(false)
                    )

                    rightRail
                    .frame(width: min(StudioLayout.harmonyPanelWidth, max(248, proxy.size.width * 0.28)))
                    .frame(maxHeight: .infinity)
                }

                ComposerEditingToolbar(
                    selectedNoteID: viewModel.selectedNoteID,
                    noteCount: viewModel.leadVoice.notes.count,
                    isPlaying: playbackController.isPlaying,
                    playbackErrorMessage: playbackController.lastErrorMessage,
                    onDelete: viewModel.deleteSelectedNote,
                    onClear: { isShowingClearConfirmation = true },
                    onNudgeLeft: { viewModel.nudgeSelectedNote(byBeats: -viewModel.leadVoice.quantizeGrid) },
                    onNudgeRight: { viewModel.nudgeSelectedNote(byBeats: viewModel.leadVoice.quantizeGrid) },
                    onShorten: { viewModel.adjustSelectedNoteDuration(byBeats: -viewModel.leadVoice.quantizeGrid) },
                    onLengthen: { viewModel.adjustSelectedNoteDuration(byBeats: viewModel.leadVoice.quantizeGrid) },
                    onVelocityDown: { viewModel.adjustSelectedNoteVelocity(by: -8) },
                    onVelocityUp: { viewModel.adjustSelectedNoteVelocity(by: 8) }
                )
            }
            .padding(StudioLayout.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .studioBackground()
        }
        .alert("Clear lead notes?", isPresented: $isShowingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearLeadNotes()
                chordGenerationViewModel.clearGeneratedChords()
                playbackController.reset()
                lastPlaybackTick = nil
            }
        } message: {
            Text("This removes every note from the piano roll.")
        }
        .onReceive(playbackTimer) { tickDate in
            advancePlaybackIfNeeded(at: tickDate)
        }
    }

    @ViewBuilder
    private var rightRail: some View {
        if viewModel.selectedNote != nil {
            ComposerSelectedNotePanel(
                composerViewModel: viewModel,
                chordViewModel: chordGenerationViewModel,
                melodyNotes: viewModel.leadVoice.notes,
                generatedProgression: chordGenerationViewModel.generatedProgression,
                key: "C",
                bpm: viewModel.bpm,
                totalBeats: viewModel.totalBeats
            )
        } else {
            ComposerHarmonyPanel(
                viewModel: chordGenerationViewModel,
                melodyNotes: viewModel.leadVoice.notes,
                generatedProgression: chordGenerationViewModel.generatedProgression,
                key: "C",
                bpm: viewModel.bpm,
                totalBeats: viewModel.totalBeats
            )
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

    private var pitchStrip: some View {
        VStack(spacing: 0) {
            ForEach(Array(stride(from: 84, through: 48, by: -6)), id: \.self) { pitch in
                Text(noteName(for: pitch))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(StudioTheme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: StudioLayout.pitchStripWidth)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private func noteName(for pitch: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return "\(names[pitch % 12])\(pitch / 12 - 1)"
    }

    private func resetPlayback() {
        playbackController.reset()
        lastPlaybackTick = nil
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

    private var transportSettings: some View {
        HStack(spacing: 14) {
            Stepper(value: $viewModel.bpm, in: 40...240, step: 1) {
                Text("BPM: \(Int(viewModel.bpm))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(maxWidth: 180)

            Stepper(value: $viewModel.barLength, in: 1...16, step: 1) {
                Text("Bars: \(viewModel.barLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.78))
            }
            .frame(maxWidth: 170)

            Toggle("Metronome", isOn: $viewModel.isMetronomeEnabled)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
                .toggleStyle(.switch)
                .frame(maxWidth: 180)

            Text("Length: \(Int(viewModel.totalBeats)) beats")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.52))

            Spacer()
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
                playbackController.bpm = viewModel.bpm
                playbackController.totalBeats = viewModel.totalBeats
                try playbackController.start(
                    leadNotes: viewModel.leadVoice.notes,
                    chordProgression: chordGenerationViewModel.generatedProgression,
                    metronomeEnabled: viewModel.isMetronomeEnabled
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
