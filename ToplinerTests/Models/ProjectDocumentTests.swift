import XCTest
@testable import Topliner

final class ProjectDocumentTests: XCTestCase {
    func testDefaultProjectIsFourBars() {
        let project = ProjectDocument(title: "New Sketch")

        XCTAssertEqual(project.title, "New Sketch")
        XCTAssertEqual(project.bpm, 120)
        XCTAssertEqual(project.beatsPerBar, 4)
        XCTAssertEqual(project.totalBars, 4)
        XCTAssertTrue(project.leadVoice.notes.isEmpty)
        XCTAssertNil(project.chordProgression)
    }

    func testCodableRoundTripPreservesBPMLeadNotesAndChordProgression() throws {
        let note = MIDINoteEvent(pitch: 62, startBeat: 0.5, durationBeats: 1, velocity: 96)
        let chord = ChordEvent(symbol: "Dm9", rootMidiNote: 62, midiNotes: [62, 65, 69, 72, 76], startBeat: 0, durationBeats: 4, romanNumeral: "ii9", confidence: 0.8)
        let project = ProjectDocument(
            title: "Neo Soul Idea",
            bpm: 92,
            key: "C",
            scale: "major",
            leadVoice: LeadVoiceBuffer(notes: [note], source: .microphone, quantizeGrid: 0.25),
            chordProgression: ChordProgression(styleID: "neo-soul", key: "C", chords: [chord], explanation: "ii color")
        )

        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(ProjectDocument.self, from: data)

        XCTAssertEqual(decoded.bpm, 92)
        XCTAssertEqual(decoded.leadVoice.notes.first?.pitch, 62)
        XCTAssertEqual(decoded.chordProgression?.chords.first?.symbol, "Dm9")
        XCTAssertEqual(decoded.chordProgression?.styleID, "neo-soul")
    }
}
