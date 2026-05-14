import XCTest
@testable import Topliner

final class QuantizerTests: XCTestCase {
    func testQuantizesBeatToNearestSixteenth() {
        XCTAssertEqual(Quantizer.quantizeBeat(0.24, grid: 0.25), 0.25, accuracy: 0.0001)
        XCTAssertEqual(Quantizer.quantizeBeat(0.12, grid: 0.25), 0.0, accuracy: 0.0001)
    }

    func testQuantizesNoteStartAndDuration() {
        let note = MIDINoteEvent(pitch: 60, startBeat: 0.26, durationBeats: 0.49, velocity: 100)
        let result = Quantizer.quantize(note: note, grid: 0.25, minimumDuration: 0.25)

        XCTAssertEqual(result.startBeat, 0.25, accuracy: 0.0001)
        XCTAssertEqual(result.durationBeats, 0.5, accuracy: 0.0001)
    }

    func testInvalidGridLeavesBeatUnchanged() {
        XCTAssertEqual(Quantizer.quantizeBeat(1.23, grid: 0), 1.23, accuracy: 0.0001)
    }
}
