import XCTest
@testable import Topliner

final class MIDINoteEventTests: XCTestCase {
    func testEndBeatAddsStartAndDuration() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 1.5, durationBeats: 0.5, velocity: 100)
        XCTAssertEqual(note.endBeat, 2.0)
    }

    func testCodableRoundTripPreservesMusicalFields() throws {
        let note = MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 90)
        let data = try JSONEncoder().encode(note)
        let decoded = try JSONDecoder().decode(MIDINoteEvent.self, from: data)

        XCTAssertEqual(decoded.pitch, 64)
        XCTAssertEqual(decoded.startBeat, 0)
        XCTAssertEqual(decoded.durationBeats, 1)
        XCTAssertEqual(decoded.velocity, 90)
    }
}
