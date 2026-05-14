import XCTest
@testable import ToplinerCore

final class ChordValidatorCoreTests: XCTestCase {
    func testAcceptsValidProgression() {
        let validator = ChordValidator()
        let progression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [validChord(symbol: "Cmaj7")],
            explanation: "ok"
        )

        XCTAssertEqual(validator.validate(progression), [])
        XCTAssertTrue(validator.isValid(progression))
    }

    func testRejectsEmptyProgression() {
        let validator = ChordValidator()
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [], explanation: nil)

        XCTAssertEqual(validator.validate(progression), [.emptyProgression])
    }

    func testFlagsNonGridAlignedTiming() {
        let validator = ChordValidator(quantizeGridBeats: 0.25)
        let chord = validChord(symbol: "Cmaj7", startBeat: 0.125, durationBeats: 1.125)
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [chord], explanation: nil)

        XCTAssertEqual(
            validator.validate(progression),
            [
                .nonGridAlignedStartBeat(chordID: chord.id, value: 0.125),
                .nonGridAlignedDuration(chordID: chord.id, value: 1.125)
            ]
        )
    }

    func testFlagsInvalidDuration() {
        let validator = ChordValidator()
        let chord = validChord(symbol: "Cmaj7", durationBeats: 0)
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [chord], explanation: nil)

        XCTAssertEqual(validator.validate(progression), [.invalidDuration(chordID: chord.id, value: 0)])
    }

    func testFlagsOutOfRangeMidiNotes() {
        let validator = ChordValidator()
        let chord = ChordEvent(
            symbol: "Cmaj7",
            rootMidiNote: 128,
            midiNotes: [48, -1, 55, 130],
            startBeat: 0,
            durationBeats: 4
        )
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [chord], explanation: nil)

        XCTAssertEqual(
            validator.validate(progression),
            [
                .invalidRootMidiNote(chordID: chord.id, value: 128),
                .invalidMidiNote(chordID: chord.id, value: -1),
                .invalidMidiNote(chordID: chord.id, value: 130)
            ]
        )
    }

    func testFlagsUnparseableChordSymbol() {
        let validator = ChordValidator()
        let chord = validChord(symbol: "Cadd9")
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [chord], explanation: nil)

        XCTAssertEqual(validator.validate(progression), [.unparseableSymbol(chordID: chord.id, symbol: "Cadd9")])
    }

    func testFlagsStyleDisallowedExtensions() {
        let profile = ChordValidationStyleProfile(
            styleID: "simple_pop",
            allowedQualities: [.major, .minor]
        )
        let validator = ChordValidator(styleProfiles: [profile])
        let chord = validChord(symbol: "Cmaj7")
        let progression = ChordProgression(styleID: "simple_pop", key: "C", chords: [chord], explanation: nil)

        XCTAssertEqual(
            validator.validate(progression),
            [.disallowedQuality(chordID: chord.id, styleID: "simple_pop", quality: .majorSeventh)]
        )
    }

    func testDefaultStyleProfilesAllowInitialNeoSoulExtensions() {
        let validator = ChordValidator()
        let progression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [
                validChord(symbol: "Cmaj9"),
                validChord(symbol: "Am9", startBeat: 4)
            ],
            explanation: nil
        )

        XCTAssertEqual(validator.validate(progression), [])
    }

    private func validChord(
        symbol: String,
        rootMidiNote: Int = 48,
        midiNotes: [Int] = [48, 52, 55, 59],
        startBeat: Double = 0,
        durationBeats: Double = 4
    ) -> ChordEvent {
        ChordEvent(
            symbol: symbol,
            rootMidiNote: rootMidiNote,
            midiNotes: midiNotes,
            startBeat: startBeat,
            durationBeats: durationBeats
        )
    }
}
