import XCTest
@testable import ToplinerCore

final class ChordGenerationResponseParserCoreTests: XCTestCase {
    func testParsesValidStrictJSONIntoChordProgression() throws {
        let parser = ChordGenerationResponseParser()
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 60,
              "midiNotes": [60, 64, 67, 71, 74],
              "startBeat": 0,
              "durationBeats": 1,
              "romanNumeral": "Imaj9",
              "confidence": 0.97
            },
            {
              "symbol": "E7alt",
              "rootMidiNote": 64,
              "midiNotes": [64, 68, 70, 74],
              "startBeat": 1,
              "durationBeats": 1,
              "romanNumeral": "III7alt",
              "confidence": 0.82
            }
          ],
          "explanation": "Supports the opening melody with lush dominant motion."
        }
        """

        let progression = try parser.parse(json)

        XCTAssertEqual(progression.styleID, "neo_soul")
        XCTAssertEqual(progression.key, "C")
        XCTAssertEqual(progression.chords.map(\.symbol), ["Cmaj9", "E7alt"])
        XCTAssertEqual(progression.chords.first?.midiNotes, [60, 64, 67, 71, 74])
        XCTAssertEqual(progression.chords.first?.startBeat, 0)
        XCTAssertEqual(progression.chords.first?.durationBeats, 1)
        XCTAssertEqual(progression.chords.first?.romanNumeral, "Imaj9")
        XCTAssertEqual(progression.chords.first?.confidence, 0.97)
        XCTAssertEqual(progression.explanation, "Supports the opening melody with lush dominant motion.")
    }

    func testRejectsMissingChords() {
        let parser = ChordGenerationResponseParser()
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "explanation": "No chords were supplied."
        }
        """

        XCTAssertThrowsError(try parser.parse(json)) { error in
            XCTAssertEqual(error as? ChordGenerationResponseParserError, .missingChords)
        }
    }

    func testRejectsEmptyChordsArray() {
        let parser = ChordGenerationResponseParser()
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": []
        }
        """

        XCTAssertThrowsError(try parser.parse(json)) { error in
            XCTAssertEqual(error as? ChordGenerationResponseParserError, .missingChords)
        }
    }

    func testRejectsInvalidMidiValues() {
        let parser = ChordGenerationResponseParser()
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 128,
              "midiNotes": [60, 64, -1],
              "startBeat": 0,
              "durationBeats": 1,
              "romanNumeral": "Imaj9",
              "confidence": 0.97
            }
          ]
        }
        """

        XCTAssertThrowsError(try parser.parse(json)) { error in
            XCTAssertEqual(error as? ChordGenerationResponseParserError, .invalidMIDIValue(128))
        }
    }

    func testRejectsNonGridAlignedStartAndDurationByDefault() {
        let parser = ChordGenerationResponseParser(quantizeGridBeats: 0.25)
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 60,
              "midiNotes": [60, 64, 67],
              "startBeat": 0.13,
              "durationBeats": 0.62,
              "romanNumeral": "Imaj9",
              "confidence": 0.97
            }
          ]
        }
        """

        XCTAssertThrowsError(try parser.parse(json)) { error in
            XCTAssertEqual(error as? ChordGenerationResponseParserError, .nonGridAlignedBeat(0.13))
        }
    }

    func testCorrectionModeQuantizesNonGridAlignedStartAndDuration() throws {
        let parser = ChordGenerationResponseParser(quantizeGridBeats: 0.25, correctionMode: .quantizeToGrid)
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 60,
              "midiNotes": [60, 64, 67],
              "startBeat": 0.13,
              "durationBeats": 0.62,
              "romanNumeral": "Imaj9",
              "confidence": 0.97
            }
          ]
        }
        """

        let progression = try parser.parse(json)

        XCTAssertEqual(progression.chords.first?.startBeat, 0.25)
        XCTAssertEqual(progression.chords.first?.durationBeats, 0.5)
    }

    func testRejectsInvalidConfidence() {
        let parser = ChordGenerationResponseParser()
        let json = """
        {
          "styleID": "neo_soul",
          "key": "C",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 60,
              "midiNotes": [60, 64, 67],
              "startBeat": 0,
              "durationBeats": 1,
              "romanNumeral": "Imaj9",
              "confidence": 1.2
            }
          ]
        }
        """

        XCTAssertThrowsError(try parser.parse(json)) { error in
            XCTAssertEqual(error as? ChordGenerationResponseParserError, .invalidConfidence(1.2))
        }
    }
}
