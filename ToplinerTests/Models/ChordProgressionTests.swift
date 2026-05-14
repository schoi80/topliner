import XCTest
@testable import Topliner

final class ChordProgressionTests: XCTestCase {
    func testCodableRoundTripPreservesChordProgressionFields() throws {
        let chord = ChordEvent(
            symbol: "Cmaj9",
            rootMidiNote: 60,
            midiNotes: [60, 64, 67, 71, 74],
            startBeat: 0,
            durationBeats: 4,
            romanNumeral: "Imaj9",
            confidence: 0.92
        )
        let progression = ChordProgression(styleID: "neo-soul", key: "C", chords: [chord], explanation: "Warm tonic color")

        let data = try JSONEncoder().encode(progression)
        let decoded = try JSONDecoder().decode(ChordProgression.self, from: data)

        XCTAssertEqual(decoded.styleID, "neo-soul")
        XCTAssertEqual(decoded.key, "C")
        XCTAssertEqual(decoded.explanation, "Warm tonic color")
        XCTAssertEqual(decoded.chords.first?.symbol, "Cmaj9")
        XCTAssertEqual(decoded.chords.first?.midiNotes, [60, 64, 67, 71, 74])
        XCTAssertEqual(decoded.chords.first?.romanNumeral, "Imaj9")
        XCTAssertEqual(decoded.chords.first?.confidence, 0.92)
    }
}
