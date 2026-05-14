import CoreGraphics
import XCTest
@testable import ToplinerCore

final class ComposerViewModelCoreTests: XCTestCase {
    func testTapOnEmptyGridAppendsDefaultNoteAtQuantizedBeatAndPitch() {
        let viewModel = ComposerViewModel()
        let geometry = makeGeometry()

        viewModel.handlePianoRollTap(at: CGPoint(x: 103, y: 1), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes.count, 1)
        let note = viewModel.leadVoice.notes[0]
        XCTAssertEqual(note.pitch, 71)
        XCTAssertEqual(note.startBeat, 4, accuracy: 0.0001)
        XCTAssertEqual(note.durationBeats, 1, accuracy: 0.0001)
        XCTAssertEqual(note.velocity, 100)
        XCTAssertEqual(viewModel.selectedNoteID, note.id)
    }

    func testTapOnExistingNoteSelectsItInsteadOfAppending() {
        let existingNote = MIDINoteEvent(pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)
        let viewModel = ComposerViewModel(leadVoice: LeadVoiceBuffer(notes: [existingNote], source: .pianoRoll, quantizeGrid: 0.25))
        let geometry = makeGeometry()
        let existingRect = geometry.rect(for: existingNote)

        viewModel.handlePianoRollTap(at: CGPoint(x: existingRect.midX, y: existingRect.midY), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes, [existingNote])
        XCTAssertEqual(viewModel.selectedNoteID, existingNote.id)
    }

    func testTapAddedNoteUsesLeadVoiceQuantizeGrid() {
        let viewModel = ComposerViewModel(leadVoice: LeadVoiceBuffer(notes: [], source: .pianoRoll, quantizeGrid: 1.0))
        let geometry = PianoRollGeometry(size: CGSize(width: 400, height: 480), pitchRange: 60...71, totalBeats: 16, quantizeGrid: viewModel.leadVoice.quantizeGrid)

        viewModel.handlePianoRollTap(at: CGPoint(x: 113, y: 1), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes[0].startBeat, 5, accuracy: 0.0001)
    }

    func testDragSelectedNoteMovesItToQuantizedBeatAndPitch() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 2, velocity: 88)],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollDrag(to: CGPoint(x: 103, y: 1), geometry: geometry)

        let movedNote = viewModel.leadVoice.notes[0]
        XCTAssertEqual(movedNote.id, selectedID)
        XCTAssertEqual(movedNote.pitch, 71)
        XCTAssertEqual(movedNote.startBeat, 4, accuracy: 0.0001)
        XCTAssertEqual(movedNote.durationBeats, 2, accuracy: 0.0001)
        XCTAssertEqual(movedNote.velocity, 88)
    }

    func testDragSelectedNoteClampsToVisiblePitchAndNonNegativeBeat() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 4, durationBeats: 1, velocity: 100)],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollDrag(to: CGPoint(x: -50, y: -50), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes[0].pitch, 71)
        XCTAssertEqual(viewModel.leadVoice.notes[0].startBeat, 0, accuracy: 0.0001)
    }

    func testDragWithoutSelectedNoteDoesNotMutateNotes() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [note], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: nil
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollDrag(to: CGPoint(x: 103, y: 1), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes, [note])
    }

    func testResizeSelectedNoteChangesDurationToQuantizedDraggedEndBeat() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 2, durationBeats: 1, velocity: 88)],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollResize(to: CGPoint(x: 113, y: 1), geometry: geometry)

        let resizedNote = viewModel.leadVoice.notes[0]
        XCTAssertEqual(resizedNote.id, selectedID)
        XCTAssertEqual(resizedNote.pitch, 60)
        XCTAssertEqual(resizedNote.startBeat, 2, accuracy: 0.0001)
        XCTAssertEqual(resizedNote.durationBeats, 2.5, accuracy: 0.0001)
        XCTAssertEqual(resizedNote.velocity, 88)
    }

    func testResizeSelectedNoteClampsToMinimumQuantizeGridDuration() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollResize(to: CGPoint(x: 50, y: 1), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes[0].durationBeats, 0.25, accuracy: 0.0001)
    }

    func testResizeWithoutSelectedNoteDoesNotMutateNotes() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [note], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: nil
        )
        let geometry = makeGeometry()

        viewModel.handlePianoRollResize(to: CGPoint(x: 113, y: 1), geometry: geometry)

        XCTAssertEqual(viewModel.leadVoice.notes, [note])
    }

    func testSelectedNoteReturnsCurrentSelection() {
        let selectedID = UUID()
        let selectedNote = MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [selectedNote], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: selectedID
        )

        XCTAssertEqual(viewModel.selectedNote, selectedNote)
    }

    func testUpdateSelectedNoteClampsMidiValuesAndQuantizesTiming() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )

        viewModel.updateSelectedNote(pitch: 200, startBeat: 1.13, durationBeats: 0.02, velocity: 190)

        let editedNote = viewModel.leadVoice.notes[0]
        XCTAssertEqual(editedNote.pitch, 127)
        XCTAssertEqual(editedNote.startBeat, 1.25, accuracy: 0.0001)
        XCTAssertEqual(editedNote.durationBeats, 0.25, accuracy: 0.0001)
        XCTAssertEqual(editedNote.velocity, 127)
    }

    func testDuplicateSelectedNoteOffsetsCopyAndSelectsIt() throws {
        let selectedID = UUID()
        let selectedNote = MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 2, durationBeats: 1, velocity: 96)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [selectedNote], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: selectedID
        )

        viewModel.duplicateSelectedNote()

        XCTAssertEqual(viewModel.leadVoice.notes.count, 2)
        let copiedNote = try XCTUnwrap(viewModel.leadVoice.notes.first { $0.id != selectedID })
        XCTAssertEqual(copiedNote.pitch, 60)
        XCTAssertEqual(copiedNote.startBeat, 3, accuracy: 0.0001)
        XCTAssertEqual(copiedNote.durationBeats, 1, accuracy: 0.0001)
        XCTAssertEqual(copiedNote.velocity, 96)
        XCTAssertEqual(viewModel.selectedNoteID, copiedNote.id)
    }

    func testNudgeSelectedNoteMovesByQuantizeGrid() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [
                MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 1, durationBeats: 1, velocity: 100)
            ], source: .pianoRoll, quantizeGrid: 0.25)
        )
        viewModel.selectedNoteID = selectedID

        viewModel.nudgeSelectedNote(byBeats: 0.25)

        XCTAssertEqual(viewModel.selectedNote?.startBeat, 1.25)
    }

    func testAdjustSelectedNoteVelocityClampsMidiRange() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [
                MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 1, durationBeats: 1, velocity: 120)
            ], source: .pianoRoll, quantizeGrid: 0.25)
        )
        viewModel.selectedNoteID = selectedID

        viewModel.adjustSelectedNoteVelocity(by: 20)

        XCTAssertEqual(viewModel.selectedNote?.velocity, 127)
    }

    func testAdjustSelectedNoteDurationClampsToQuantizeGrid() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [
                MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 1, durationBeats: 0.25, velocity: 100)
            ], source: .pianoRoll, quantizeGrid: 0.25)
        )
        viewModel.selectedNoteID = selectedID

        viewModel.adjustSelectedNoteDuration(byBeats: -1)

        XCTAssertEqual(viewModel.selectedNote?.durationBeats, 0.25)
    }

    func testDeleteSelectedNoteRemovesOnlySelectedNoteAndClearsSelection() {
        let selectedID = UUID()
        let selectedNote = MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)
        let remainingNote = MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [selectedNote, remainingNote], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: selectedID
        )

        viewModel.deleteSelectedNote()

        XCTAssertEqual(viewModel.leadVoice.notes, [remainingNote])
        XCTAssertNil(viewModel.selectedNoteID)
    }

    func testDeleteSelectedNoteWithNoSelectionDoesNotMutateNotes() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(notes: [note], source: .pianoRoll, quantizeGrid: 0.25),
            selectedNoteID: nil
        )

        viewModel.deleteSelectedNote()

        XCTAssertEqual(viewModel.leadVoice.notes, [note])
        XCTAssertNil(viewModel.selectedNoteID)
    }

    func testClearLeadNotesRemovesAllNotesAndClearsSelection() {
        let selectedID = UUID()
        let viewModel = ComposerViewModel(
            leadVoice: LeadVoiceBuffer(
                notes: [
                    MIDINoteEvent(id: selectedID, pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
                    MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100)
                ],
                source: .pianoRoll,
                quantizeGrid: 0.25
            ),
            selectedNoteID: selectedID
        )

        viewModel.clearLeadNotes()

        XCTAssertTrue(viewModel.leadVoice.notes.isEmpty)
        XCTAssertNil(viewModel.selectedNoteID)
    }

    func testSessionSettingsDefaultToFourBarsAt120BPMWithMetronomeOff() {
        let viewModel = ComposerViewModel()

        XCTAssertEqual(viewModel.bpm, 120)
        XCTAssertEqual(viewModel.barLength, 4)
        XCTAssertEqual(viewModel.totalBeats, 16)
        XCTAssertFalse(viewModel.isMetronomeEnabled)
    }

    func testSessionSettingsClampBPMAndBarLength() {
        let viewModel = ComposerViewModel()

        viewModel.bpm = 12
        viewModel.barLength = 99

        XCTAssertEqual(viewModel.bpm, 40)
        XCTAssertEqual(viewModel.barLength, 16)
        XCTAssertEqual(viewModel.totalBeats, 64)

        viewModel.bpm = 400
        viewModel.barLength = 0

        XCTAssertEqual(viewModel.bpm, 240)
        XCTAssertEqual(viewModel.barLength, 1)
        XCTAssertEqual(viewModel.totalBeats, 4)
    }

    private func makeGeometry() -> PianoRollGeometry {
        PianoRollGeometry(size: CGSize(width: 400, height: 480), pitchRange: 60...71, totalBeats: 16, quantizeGrid: 0.25)
    }
}
