import SwiftUI

struct PianoRollDrawableNote: Equatable {
    var note: MIDINoteEvent
    var rect: CGRect
    var isSelected: Bool
    var track: PianoRollNoteTrack = .lead

    var isEditable: Bool { track == .lead }

    var resizeHandleRect: CGRect? {
        guard isSelected, isEditable else { return nil }
        let width = min(8, rect.width)
        return CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height)
    }
}

enum PianoRollNoteTrack: Equatable {
    case lead
    case chords
}

struct PianoRollNoteLayout {
    var notes: [MIDINoteEvent]
    var chordNotes: [MIDINoteEvent] = []
    var selectedNoteID: UUID?
    var geometry: PianoRollGeometry

    func drawableNotes() -> [PianoRollDrawableNote] {
        let chordDrawables = chordNotes
            .filter { geometry.pitchRange.contains($0.pitch) }
            .map { note in
                PianoRollDrawableNote(
                    note: note,
                    rect: geometry.rect(for: note),
                    isSelected: false,
                    track: .chords
                )
            }
        let leadDrawables = notes
            .filter { geometry.pitchRange.contains($0.pitch) }
            .map { note in
                PianoRollDrawableNote(
                    note: note,
                    rect: geometry.rect(for: note),
                    isSelected: note.id == selectedNoteID,
                    track: .lead
                )
            }
        return chordDrawables + leadDrawables
    }
}

struct PianoRollCanvasView: View {
    var notes: [MIDINoteEvent]
    var chordNotes: [MIDINoteEvent] = []
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
            let layout = PianoRollNoteLayout(
                notes: notes,
                chordNotes: chordNotes,
                selectedNoteID: selectedNoteID,
                geometry: geometry
            )

            for drawableNote in layout.drawableNotes() {
                draw(drawableNote, in: &context)
            }
        }
        .accessibilityLabel("Piano roll notes")
    }

    private func draw(_ drawableNote: PianoRollDrawableNote, in context: inout GraphicsContext) {
        let path = Path(roundedRect: drawableNote.rect, cornerRadius: 5)
        let fill: Color
        if drawableNote.track == .chords {
            fill = Color(red: 0.88, green: 0.48, blue: 1.0).opacity(0.55)
        } else if drawableNote.isSelected {
            fill = Color(red: 0.42, green: 0.95, blue: 1.0).opacity(0.92)
        } else {
            fill = Color(red: 0.34, green: 0.64, blue: 1.0).opacity(0.82)
        }
        let stroke = drawableNote.isSelected
            ? Color.white.opacity(0.9)
            : Color.white.opacity(drawableNote.track == .chords ? 0.42 : 0.28)

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
        chordNotes: [
            MIDINoteEvent(pitch: 48, startBeat: 0, durationBeats: 4, velocity: 82),
            MIDINoteEvent(pitch: 52, startBeat: 0, durationBeats: 4, velocity: 82),
            MIDINoteEvent(pitch: 55, startBeat: 0, durationBeats: 4, velocity: 82)
        ],
        selectedNoteID: nil
    )
    .frame(height: 360)
    .padding()
    .background(Color.black)
}
