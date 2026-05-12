import XCTest
@testable import Topliner

final class LeadVoiceBufferTests: XCTestCase {
    func testSortedNotesOrdersByStartBeatThenPitch() {
        let high = MIDINoteEvent(pitch: 72, startBeat: 1, durationBeats: 1, velocity: 100)
        let low = MIDINoteEvent(pitch: 60, startBeat: 1, durationBeats: 1, velocity: 100)
        let first = MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 100)
        let buffer = LeadVoiceBuffer(notes: [high, first, low], source: .pianoRoll, quantizeGrid: 0.25)

        XCTAssertEqual(buffer.sortedNotes.map(\.pitch), [64, 60, 72])
    }
}
