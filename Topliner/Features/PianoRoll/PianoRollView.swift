import SwiftUI

struct PianoRollView: View {
    var notes: [MIDINoteEvent]
    var selectedNoteID: UUID?
    var totalBeats: Double = 16
    var beatsPerBar: Int = 4
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25

    var body: some View {
        ZStack {
            PianoRollGridView(totalBeats: totalBeats, beatsPerBar: beatsPerBar, pitchRange: pitchRange)
            PianoRollCanvasView(
                notes: notes,
                selectedNoteID: selectedNoteID,
                totalBeats: totalBeats,
                pitchRange: pitchRange,
                quantizeGrid: quantizeGrid
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    PianoRollView(
        notes: [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 67, startBeat: 2, durationBeats: 2, velocity: 100),
            MIDINoteEvent(pitch: 72, startBeat: 5, durationBeats: 1.5, velocity: 100)
        ],
        selectedNoteID: nil
    )
    .frame(height: 360)
    .padding()
    .background(Color.black)
}
