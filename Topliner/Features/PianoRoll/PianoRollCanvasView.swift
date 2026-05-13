import SwiftUI

struct PianoRollDrawableNote: Equatable {
    var note: MIDINoteEvent
    var rect: CGRect
    var isSelected: Bool

    var resizeHandleRect: CGRect? {
        guard isSelected else { return nil }
        let width = min(8, rect.width)
        return CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height)
    }
}

struct PianoRollNoteLayout {
    var notes: [MIDINoteEvent]
    var selectedNoteID: UUID?
    var geometry: PianoRollGeometry

    func drawableNotes() -> [PianoRollDrawableNote] {
        notes
            .filter { geometry.pitchRange.contains($0.pitch) }
            .map { note in
                PianoRollDrawableNote(
                    note: note,
                    rect: geometry.rect(for: note),
                    isSelected: note.id == selectedNoteID
                )
            }
    }
}

struct PianoRollCanvasView: View {
    var notes: [MIDINoteEvent]
    var selectedNoteID: UUID?
    var totalBeats: Double = 16
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25

    var body: some View {
        Canvas { context, size in
            let geometry = PianoRollGeometry(
                size: size,
                pitchRange: pitchRange,
                totalBeats: totalBeats,
                quantizeGrid: quantizeGrid
            )
            let layout = PianoRollNoteLayout(notes: notes, selectedNoteID: selectedNoteID, geometry: geometry)

            for drawableNote in layout.drawableNotes() {
                draw(drawableNote, in: &context)
            }
        }
        .accessibilityLabel("Piano roll notes")
    }

    private func draw(_ drawableNote: PianoRollDrawableNote, in context: inout GraphicsContext) {
        let path = Path(roundedRect: drawableNote.rect, cornerRadius: 5)
        let fill = drawableNote.isSelected
            ? Color(red: 0.42, green: 0.95, blue: 1.0).opacity(0.92)
            : Color(red: 0.34, green: 0.64, blue: 1.0).opacity(0.82)
        let stroke = drawableNote.isSelected
            ? Color.white.opacity(0.9)
            : Color.white.opacity(0.28)

        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(stroke), lineWidth: drawableNote.isSelected ? 2 : 1)

        if let resizeHandleRect = drawableNote.resizeHandleRect {
            let handlePath = Path(roundedRect: resizeHandleRect.insetBy(dx: 1.5, dy: 5), cornerRadius: 3)
            context.fill(handlePath, with: .color(Color.white.opacity(0.78)))
        }
    }
}

#Preview {
    PianoRollCanvasView(
        notes: [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 67, startBeat: 2, durationBeats: 2, velocity: 100)
        ],
        selectedNoteID: nil
    )
    .frame(height: 360)
    .padding()
    .background(Color.black)
}
