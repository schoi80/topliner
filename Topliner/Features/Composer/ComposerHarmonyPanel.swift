import SwiftUI

struct ComposerHarmonyPanel: View {
    @Bindable var viewModel: ChordGenerationViewModel
    var melodyNotes: [MIDINoteEvent]
    var generatedProgression: ChordProgression?
    var key: String
    var bpm: Double
    var totalBeats: Double

    private var panelModel: ComposerHarmonyPanelModel {
        ComposerHarmonyPanelModel(
            progression: generatedProgression,
            isGenerating: viewModel.isGenerating,
            variantIndex: max(0, viewModel.generationCount - 1)
        )
    }

    var body: some View {
        StudioPanel("Studio Console", subtitle: panelModel.statusMessage) {
            VStack(alignment: .leading, spacing: 14) {
                progressionPreview
                generationControls
                generationAction
                generationStatus
                exportAction
            }
        }
    }

    @ViewBuilder
    private var progressionPreview: some View {
        if panelModel.chordChips.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Progression")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)

                Text("Generate chords to fill this rail with compact harmony blocks.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Progression")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 7)], spacing: 7) {
                    ForEach(panelModel.chordChips) { chip in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chip.symbol)
                                .font(.caption.monospaced().weight(.bold))
                                .foregroundStyle(StudioTheme.textPrimary)
                                .lineLimit(1)
                            Text(chip.detail)
                                .font(.caption2.monospaced())
                                .foregroundStyle(StudioTheme.textMuted)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(StudioTheme.violet.opacity(0.20))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(StudioTheme.violet.opacity(0.42), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var generationControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Style") {
                Picker("Style", selection: $viewModel.selectedStyleID) {
                    ForEach(viewModel.availableStyles) { style in
                        Text(style.displayName).tag(style.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Complexity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textSecondary)

                Picker("Complexity", selection: $viewModel.selectedComplexity) {
                    ForEach(ChordGenerationComplexity.allCases) { complexity in
                        Text(complexity.displayName).tag(complexity)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 8) {
                StudioControlChip(title: "Key", value: key, systemImage: "music.quarternote.3")
                StudioControlChip(title: "Bars", value: "\(Int(totalBeats / 4))", systemImage: "repeat")
            }
        }
        .font(.caption)
        .foregroundStyle(StudioTheme.textSecondary)
    }

    private var generationAction: some View {
        Button {
            viewModel.generateChords(
                melodyNotes: melodyNotes,
                key: key,
                bpm: bpm,
                totalBeats: totalBeats
            )
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: generatedProgression == nil ? "sparkles" : "arrow.triangle.2.circlepath")
                }
                Text(panelModel.primaryActionTitle)
                    .font(.caption.weight(.bold))
                Spacer()
            }
            .frame(minHeight: StudioLayout.minimumTouchTarget)
        }
        .disabled(viewModel.isGenerating || viewModel.selectedStyleID.isEmpty)
        .buttonStyle(.borderedProminent)
        .tint(StudioTheme.violet)
    }

    @ViewBuilder
    private var generationStatus: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(StudioTheme.danger)
                .fixedSize(horizontal: false, vertical: true)
        } else if let summary = viewModel.chordLaneSummary {
            Text(summary)
                .font(.caption.monospaced())
                .foregroundStyle(StudioTheme.lime)
                .lineLimit(2)
        } else {
            Text("Uses the current melody, loop length, style, and complexity.")
                .font(.caption)
                .foregroundStyle(StudioTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exportAction: some View {
        MIDIExportShareView(
            leadNotes: melodyNotes,
            chordProgression: generatedProgression,
            bpm: bpm
        )
    }
}
