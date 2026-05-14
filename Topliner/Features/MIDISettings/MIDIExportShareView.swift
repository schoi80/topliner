import SwiftUI

struct MIDIExportShareView: View {
    let leadNotes: [MIDINoteEvent]
    let chordProgression: ChordProgression?
    let bpm: Double

    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export MIDI File", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    prepareExport()
                } label: {
                    Label("Prepare MIDI Export", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear(perform: prepareExport)
        .onChange(of: leadNotes) { _, _ in prepareExport() }
        .onChange(of: chordProgression) { _, _ in prepareExport() }
        .onChange(of: bpm) { _, _ in prepareExport() }
    }

    private func prepareExport() {
        do {
            exportURL = try MIDIFileExporter().writeExportFile(
                leadNotes: leadNotes,
                chordProgression: chordProgression,
                bpm: bpm,
                fileName: "Topliner Sketch.mid"
            )
            errorMessage = nil
        } catch {
            exportURL = nil
            errorMessage = "Could not prepare MIDI export."
        }
    }
}

#Preview {
    MIDIExportShareView(leadNotes: [], chordProgression: nil, bpm: 120)
}
