import CoreGraphics
import XCTest
@testable import ToplinerCore

final class PianoRollNoteLayoutCoreTests: XCTestCase {
    func testReturnsDrawableNotesForVisiblePitchRange() {
        let layout = PianoRollNoteLayout(
            notes: [MIDINoteEvent(pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)],
            selectedNoteID: nil,
            geometry: makeGeometry()
        )

        let drawableNotes = layout.drawableNotes()

        XCTAssertEqual(drawableNotes.count, 1)
        XCTAssertEqual(drawableNotes[0].rect.origin.x, 100, accuracy: 0.0001)
        XCTAssertEqual(drawableNotes[0].rect.width, 50, accuracy: 0.0001)
        XCTAssertFalse(drawableNotes[0].isSelected)
    }

    func testMarksSelectedNote() {
        let selectedID = UUID()
        let layout = PianoRollNoteLayout(
            notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)],
            selectedNoteID: selectedID,
            geometry: makeGeometry()
        )

        let drawableNotes = layout.drawableNotes()

        XCTAssertTrue(drawableNotes[0].isSelected)
    }

    func testSelectedNoteHasTrailingResizeHandleRect() {
        let selectedID = UUID()
        let layout = PianoRollNoteLayout(
            notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)],
            selectedNoteID: selectedID,
            geometry: makeGeometry()
        )

        let drawableNote = layout.drawableNotes()[0]

        XCTAssertEqual(drawableNote.resizeHandleRect, CGRect(x: 142, y: 440, width: 8, height: 40))
    }

    func testUnselectedNoteDoesNotHaveResizeHandleRect() {
        let layout = PianoRollNoteLayout(
            notes: [MIDINoteEvent(pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)],
            selectedNoteID: nil,
            geometry: makeGeometry()
        )

        XCTAssertNil(layout.drawableNotes()[0].resizeHandleRect)
    }

    func testFiltersNotesOutsideVisiblePitchRange() {
        let layout = PianoRollNoteLayout(
            notes: [
                MIDINoteEvent(pitch: 59, startBeat: 0, durationBeats: 1, velocity: 100),
                MIDINoteEvent(pitch: 60, startBeat: 1, durationBeats: 1, velocity: 100),
                MIDINoteEvent(pitch: 72, startBeat: 2, durationBeats: 1, velocity: 100)
            ],
            selectedNoteID: nil,
            geometry: makeGeometry()
        )

        let drawableNotes = layout.drawableNotes()

        XCTAssertEqual(drawableNotes.map(\.note.pitch), [60])
    }

    private func makeGeometry() -> PianoRollGeometry {
        PianoRollGeometry(size: CGSize(width: 400, height: 480), pitchRange: 60...71, totalBeats: 16, quantizeGrid: 0.25)
    }
}
