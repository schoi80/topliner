import SwiftUI

struct PianoRollView: View {
    var notes: [MIDINoteEvent]
    var selectedNoteID: UUID?
    var totalBeats: Double = 16
    var beatsPerBar: Int = 4
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25
    var onTap: ((CGPoint, PianoRollGeometry) -> Void)?
    var onDrag: ((CGPoint, PianoRollGeometry) -> Void)?
    var onResize: ((CGPoint, PianoRollGeometry) -> Void)?

    init(
        notes: [MIDINoteEvent],
        selectedNoteID: UUID?,
        totalBeats: Double = 16,
        beatsPerBar: Int = 4,
        pitchRange: ClosedRange<Int> = 48...84,
        quantizeGrid: Double = 0.25,
        onTap: ((CGPoint, PianoRollGeometry) -> Void)? = nil,
        onDrag: ((CGPoint, PianoRollGeometry) -> Void)? = nil,
        onResize: ((CGPoint, PianoRollGeometry) -> Void)? = nil
    ) {
        self.notes = notes
        self.selectedNoteID = selectedNoteID
        self.totalBeats = totalBeats
        self.beatsPerBar = beatsPerBar
        self.pitchRange = pitchRange
        self.quantizeGrid = quantizeGrid
        self.onTap = onTap
        self.onDrag = onDrag
        self.onResize = onResize
    }

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

            if let onTap {
                PianoRollInteractionLayer(
                    notes: notes,
                    selectedNoteID: selectedNoteID,
                    totalBeats: totalBeats,
                    pitchRange: pitchRange,
                    quantizeGrid: quantizeGrid,
                    onTap: onTap,
                    onDrag: onDrag,
                    onResize: onResize
                )
            }
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
