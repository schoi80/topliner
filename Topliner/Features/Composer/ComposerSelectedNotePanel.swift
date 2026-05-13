import SwiftUI

struct ComposerSelectedNotePanel: View {
    @Bindable var composerViewModel: ComposerViewModel
    @Bindable var chordViewModel: ChordGenerationViewModel
    var melodyNotes: [MIDINoteEvent]
    var generatedProgression: ChordProgression?
    var key: String
    var bpm: Double
    var totalBeats: Double

    private var note: MIDINoteEvent? { composerViewModel.selectedNote }

    private var harmonyModel: ComposerHarmonyPanelModel {
        ComposerHarmonyPanelModel(
            progression: generatedProgression,
            isGenerating: chordViewModel.isGenerating,
            variantIndex: max(0, chordViewModel.generationCount - 1)
        )
    }

    var body: some View {
        StudioPanel("Note Inspector", subtitle: noteSubtitle) {
            VStack(alignment: .leading, spacing: 14) {
                if note != nil {
                    noteControls
                    noteActions
                    Divider().overlay(StudioTheme.border)
                    compactHarmonyControls
                } else {
                    Text("Select a MIDI note to edit pitch, timing, duration, and velocity.")
                        .font(.caption)
                        .foregroundStyle(StudioTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var noteSubtitle: String {
        guard let note else { return "No note selected" }
        return "\(noteName(for: note.pitch)) · beat \(formatBeat(note.startBeat)) · vel \(note.velocity)"
    }

    private var noteControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorStepper("Pitch", value: pitchBinding, range: 0...127, step: 1, formattedValue: note.map { noteName(for: $0.pitch) } ?? "—")
            inspectorDoubleStepper("Start", value: startBinding, range: 0...totalBeats, step: composerViewModel.leadVoice.quantizeGrid, formattedValue: note.map { formatBeat($0.startBeat) } ?? "—")
            inspectorDoubleStepper("Duration", value: durationBinding, range: composerViewModel.leadVoice.quantizeGrid...totalBeats, step: composerViewModel.leadVoice.quantizeGrid, formattedValue: note.map { formatBeat($0.durationBeats) } ?? "—")
            inspectorStepper("Velocity", value: velocityBinding, range: 0...127, step: 1, formattedValue: note.map { "\($0.velocity)" } ?? "—")
        }
    }

    private func inspectorStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, formattedValue: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)
                Spacer()
                Text(formattedValue)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
            }
        }
        .tint(StudioTheme.cyan)
    }

    private func inspectorDoubleStepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, formattedValue: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)
                Spacer()
                Text(formattedValue)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
            }
        }
        .tint(StudioTheme.cyan)
    }

    private var noteActions: some View {
        HStack(spacing: 8) {
            Button {
                composerViewModel.duplicateSelectedNote()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(StudioTheme.cyan)

            Button(role: .destructive) {
                composerViewModel.deleteSelectedNote()
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(StudioTheme.danger)
        }
        .font(.caption.weight(.semibold))
    }

    private var compactHarmonyControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Harmony")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(StudioTheme.textSecondary)

            if harmonyModel.chordChips.isEmpty {
                Text("Generate chords around the edited melody.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.textMuted)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                    ForEach(harmonyModel.chordChips.prefix(4)) { chip in
                        Text(chip.symbol)
                            .font(.caption.monospaced().weight(.semibold))
                            .lineLimit(1)
                            .foregroundStyle(StudioTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(StudioTheme.violet.opacity(0.20))
                            )
                    }
                }
            }

            Picker("Complexity", selection: $chordViewModel.selectedComplexity) {
                ForEach(ChordGenerationComplexity.allCases) { complexity in
                    Text(complexity.displayName).tag(complexity)
                }
            }
            .pickerStyle(.segmented)

            Button {
                chordViewModel.generateChords(
                    melodyNotes: melodyNotes,
                    key: key,
                    bpm: bpm,
                    totalBeats: totalBeats
                )
            } label: {
                Label(harmonyModel.primaryActionTitle, systemImage: generatedProgression == nil ? "sparkles" : "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: StudioLayout.minimumTouchTarget)
            }
            .buttonStyle(.borderedProminent)
            .tint(StudioTheme.violet)
            .disabled(chordViewModel.isGenerating || chordViewModel.selectedStyleID.isEmpty)
        }
    }

    private var pitchBinding: Binding<Int> {
        Binding(
            get: { note?.pitch ?? 60 },
            set: { newValue in updateSelectedNote(pitch: newValue) }
        )
    }

    private var startBinding: Binding<Double> {
        Binding(
            get: { note?.startBeat ?? 0 },
            set: { newValue in updateSelectedNote(startBeat: newValue) }
        )
    }

    private var durationBinding: Binding<Double> {
        Binding(
            get: { note?.durationBeats ?? composerViewModel.leadVoice.quantizeGrid },
            set: { newValue in updateSelectedNote(durationBeats: newValue) }
        )
    }

    private var velocityBinding: Binding<Int> {
        Binding(
            get: { note?.velocity ?? 100 },
            set: { newValue in updateSelectedNote(velocity: newValue) }
        )
    }

    private func updateSelectedNote(pitch: Int? = nil, startBeat: Double? = nil, durationBeats: Double? = nil, velocity: Int? = nil) {
        guard let note else { return }
        composerViewModel.updateSelectedNote(
            pitch: pitch ?? note.pitch,
            startBeat: startBeat ?? note.startBeat,
            durationBeats: durationBeats ?? note.durationBeats,
            velocity: velocity ?? note.velocity
        )
    }

    private func noteName(for pitch: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return "\(names[pitch % 12])\(pitch / 12 - 1)"
    }

    private func formatBeat(_ beat: Double) -> String {
        if beat.rounded() == beat {
            return "\(Int(beat))"
        }
        return String(format: "%.2f", beat)
    }
}
