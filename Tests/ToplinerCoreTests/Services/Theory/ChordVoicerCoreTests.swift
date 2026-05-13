import XCTest
@testable import ToplinerCore

final class ChordVoicerCoreTests: XCTestCase {
    func testDefaultCloseVoicingUsesC3ToC5Range() throws {
        let voicer = ChordVoicer()

        let notes = try voicer.voice(symbol: "Cmaj7")

        XCTAssertEqual(notes, [48, 52, 55, 59])
        XCTAssertTrue(notes.allSatisfy { (48...72).contains($0) })
    }

    func testVoiceLeadingKeepsCommonTonesAndMinimizesMovement() throws {
        let voicer = ChordVoicer()
        let previous = try voicer.voice(symbol: "Cmaj7")

        let next = try voicer.voice(symbol: "G7", previousVoicing: previous)

        XCTAssertEqual(next, [50, 53, 55, 59])
        XCTAssertTrue(next.contains(55), "G should remain a common tone")
        XCTAssertTrue(next.contains(59), "B should remain a common tone")
        XCTAssertLessThan(totalMovement(from: previous, to: next), totalMovement(from: previous, to: [55, 59, 62, 65]))
    }

    func testOpenStyleSpreadsChordAcrossDefaultRange() throws {
        let voicer = ChordVoicer()

        let notes = try voicer.voice(symbol: "Cmaj7", style: .open)

        XCTAssertEqual(notes, [48, 55, 64, 71])
        XCTAssertGreaterThan(notes.last! - notes.first!, 12)
    }

    func testDropTwoLikeStyleDropsSecondVoiceFromTop() throws {
        let voicer = ChordVoicer()

        let notes = try voicer.voice(symbol: "Cmaj7", style: .dropTwo)

        XCTAssertEqual(notes, [48, 55, 59, 64])
        XCTAssertTrue(notes.allSatisfy { (48...72).contains($0) })
    }

    func testCanIncludeOptionalBassRootBelowVoicing() throws {
        let voicer = ChordVoicer()

        let notes = try voicer.voice(symbol: "Cmaj7", includeBassRoot: true)

        XCTAssertEqual(notes, [36, 48, 52, 55, 59])
        XCTAssertEqual(notes.first, 36)
    }

    func testVoicesAccidentalRootWithinRange() throws {
        let voicer = ChordVoicer()

        let notes = try voicer.voice(symbol: "Dbmaj7")

        XCTAssertEqual(notes, [49, 53, 56, 60])
    }

    private func totalMovement(from previous: [Int], to next: [Int]) -> Int {
        zip(previous, next).reduce(0) { total, pair in
            total + abs(pair.0 - pair.1)
        }
    }
}
