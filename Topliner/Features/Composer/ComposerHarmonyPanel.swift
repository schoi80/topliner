import SwiftUI

struct ComposerHarmonyPanel: View {
    @Bindable var viewModel: ChordGenerationViewModel
    var melodyNotes: [MIDINoteEvent]
    var generatedProgression: ChordProgression?
    var key: String
    var bpm: Double
    var totalBeats: Double

    var body: some View {
        StudioPanel("Studio Console", subtitle: "Chord generation") {
            VStack(alignment: .leading, spacing: 14) {
                progressionPreview

                ChordGenerationView(
                    viewModel: viewModel,
                    melodyNotes: melodyNotes,
                    key: key,
                    bpm: bpm,
                    totalBeats: totalBeats
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                MIDIExportShareView(
                    leadNotes: melodyNotes,
                    chordProgression: generatedProgression,
                    bpm: bpm
                )
            }
        }
    }

    @ViewBuilder
    private var progressionPreview: some View {
        if let generatedProgression, !generatedProgression.chords.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Progression")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 6)], spacing: 6) {
                    ForEach(Array(generatedProgression.chords.prefix(8).enumerated()), id: \.offset) { _, chord in
                        Text(chord.symbol)
                            .font(.caption.monospaced().weight(.semibold))
                            .foregroundStyle(StudioTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(StudioTheme.violet.opacity(0.22))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(StudioTheme.violet.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
        } else {
            Text("Generate a progression to preview chord blocks here.")
                .font(.caption)
                .foregroundStyle(StudioTheme.textMuted)
        }
    }
}
