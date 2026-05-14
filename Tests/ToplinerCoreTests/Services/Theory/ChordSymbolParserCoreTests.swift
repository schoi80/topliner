import XCTest
@testable import ToplinerCore

final class ChordSymbolParserCoreTests: XCTestCase {
    func testParsesMajorTriadDefaultQuality() throws {
        let parser = ChordSymbolParser()

        let chord = try parser.parse("C")

        XCTAssertEqual(chord.symbol, "C")
        XCTAssertEqual(chord.rootName, "C")
        XCTAssertEqual(chord.rootPitchClass, 0)
        XCTAssertEqual(chord.quality, .major)
        XCTAssertEqual(chord.intervals, [0, 4, 7])
    }

    func testParsesInitialSupportedChordQualities() throws {
        let parser = ChordSymbolParser()
        let expectations: [(String, ChordQuality, [Int])] = [
            ("Cm", .minor, [0, 3, 7]),
            ("Cmaj7", .majorSeventh, [0, 4, 7, 11]),
            ("Cm7", .minorSeventh, [0, 3, 7, 10]),
            ("C7", .dominantSeventh, [0, 4, 7, 10]),
            ("Cdim7", .diminishedSeventh, [0, 3, 6, 9]),
            ("Cø7", .halfDiminishedSeventh, [0, 3, 6, 10]),
            ("Cmaj9", .majorNinth, [0, 4, 7, 11, 14]),
            ("Cm9", .minorNinth, [0, 3, 7, 10, 14]),
            ("C9", .dominantNinth, [0, 4, 7, 10, 14]),
            ("C11", .dominantEleventh, [0, 4, 7, 10, 14, 17]),
            ("Cm11", .minorEleventh, [0, 3, 7, 10, 14, 17]),
            ("C13", .dominantThirteenth, [0, 4, 7, 10, 14, 17, 21]),
            ("C13sus", .dominantThirteenthSuspended, [0, 5, 7, 10, 14, 21])
        ]

        for (symbol, quality, intervals) in expectations {
            let chord = try parser.parse(symbol)
            XCTAssertEqual(chord.quality, quality, symbol)
            XCTAssertEqual(chord.intervals, intervals, symbol)
        }
    }

    func testParsesAccidentalRoots() throws {
        let parser = ChordSymbolParser()

        let dFlat = try parser.parse("Dbmaj7")
        let cSharp = try parser.parse("C#m7")
        let bFlat = try parser.parse("Bb13")

        XCTAssertEqual(dFlat.rootName, "Db")
        XCTAssertEqual(dFlat.rootPitchClass, 1)
        XCTAssertEqual(cSharp.rootName, "C#")
        XCTAssertEqual(cSharp.rootPitchClass, 1)
        XCTAssertEqual(bFlat.rootName, "Bb")
        XCTAssertEqual(bFlat.rootPitchClass, 10)
    }

    func testBuildsMidiNotesFromRootMidiNote() throws {
        let parser = ChordSymbolParser()

        let chord = try parser.parse("Fmaj9")

        XCTAssertEqual(chord.midiNotes(rootMidiNote: 53), [53, 57, 60, 64, 67])
    }

    func testRejectsUnsupportedQuality() {
        let parser = ChordSymbolParser()

        XCTAssertThrowsError(try parser.parse("Cadd9")) { error in
            XCTAssertEqual(error as? ChordSymbolParserError, .unsupportedQuality("add9"))
        }
    }

    func testRejectsInvalidRoot() {
        let parser = ChordSymbolParser()

        XCTAssertThrowsError(try parser.parse("Hmaj7")) { error in
            XCTAssertEqual(error as? ChordSymbolParserError, .invalidRoot("H"))
        }
    }
}
