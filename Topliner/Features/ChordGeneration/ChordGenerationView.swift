import SwiftUI

struct ChordGenerationView: View {
    @Bindable var viewModel: ChordGenerationViewModel
    var melodyNotes: [MIDINoteEvent]
    var key: String
    var bpm: Double
    var totalBeats: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            controls
            resultLane
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Chord Generation")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Choose a style, then generate harmony for the current melody.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            StylePickerView(styles: viewModel.availableStyles, selectedStyleID: $viewModel.selectedStyleID)
                .frame(maxWidth: 220)

            Picker("Complexity", selection: $viewModel.selectedComplexity) {
                ForEach(ChordGenerationComplexity.allCases) { complexity in
                    Text(complexity.displayName).tag(complexity)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)

            Spacer(minLength: 8)

            Button {
                viewModel.generateChords(
                    melodyNotes: melodyNotes,
                    key: key,
                    bpm: bpm,
                    totalBeats: totalBeats
                )
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Generate", systemImage: "sparkles")
                }
            }
            .disabled(viewModel.isGenerating || viewModel.selectedStyleID.isEmpty)
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
    }

    @ViewBuilder
    private var resultLane: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red.opacity(0.9))
        } else if let summary = viewModel.chordLaneSummary {
            VStack(alignment: .leading, spacing: 6) {
                Text("Chord lane")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
                Text(summary)
                    .font(.callout.monospaced())
                    .foregroundStyle(.mint)
                    .lineLimit(2)
            }
        } else {
            Text("No chords generated yet.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.48))
        }
    }
}

#Preview {
    ChordGenerationView(
        viewModel: ChordGenerationViewModel(),
        melodyNotes: [],
        key: "C",
        bpm: 120,
        totalBeats: 16
    )
    .padding()
    .background(Color(red: 0.025, green: 0.028, blue: 0.038))
}
