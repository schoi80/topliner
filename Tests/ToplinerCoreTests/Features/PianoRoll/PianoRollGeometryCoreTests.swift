import CoreGraphics
import XCTest
@testable import ToplinerCore

final class PianoRollGeometryCoreTests: XCTestCase {
    func testLeftAndRightEdgesMapToBeatRange() {
        let geometry = makeGeometry()

        XCTAssertEqual(geometry.beat(atX: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(geometry.beat(atX: 400), 16, accuracy: 0.0001)
    }

    func testTopAndBottomRowsMapToPitchRange() {
        let geometry = makeGeometry()

        XCTAssertEqual(geometry.pitch(atY: 0), 71)
        XCTAssertEqual(geometry.pitch(atY: 479), 60)
    }

    func testNoteRectWidthScalesWithDurationAndTotalBeats() {
        let geometry = makeGeometry()
        let note = MIDINoteEvent(pitch: 60, startBeat: 4, durationBeats: 2, velocity: 100)

        let rect = geometry.rect(for: note)

        XCTAssertEqual(rect.origin.x, 100, accuracy: 0.0001)
        XCTAssertEqual(rect.width, 50, accuracy: 0.0001)
    }

    func testNoteStartMapsPointToPitchAndQuantizedBeat() {
        let geometry = makeGeometry()

        let result = geometry.noteStart(at: CGPoint(x: 103, y: 1))

        XCTAssertEqual(result.pitch, 71)
        XCTAssertEqual(result.beat, 4, accuracy: 0.0001)
    }

    func testGeometryCanMapScrolledVisibleBeatWindow() {
        let geometry = PianoRollGeometry(
            size: CGSize(width: 400, height: 480),
            pitchRange: 60...71,
            startBeat: 4,
            visibleBeats: 8,
            quantizeGrid: 0.25
        )
        let note = MIDINoteEvent(pitch: 60, startBeat: 6, durationBeats: 2, velocity: 100)

        XCTAssertEqual(geometry.beat(atX: 0), 4, accuracy: 0.0001)
        XCTAssertEqual(geometry.beat(atX: 400), 12, accuracy: 0.0001)
        XCTAssertEqual(geometry.rect(for: note).origin.x, 100, accuracy: 0.0001)
        XCTAssertEqual(geometry.rect(for: note).width, 100, accuracy: 0.0001)
    }

    private func makeGeometry() -> PianoRollGeometry {
        PianoRollGeometry(size: CGSize(width: 400, height: 480), pitchRange: 60...71, totalBeats: 16, quantizeGrid: 0.25)
    }
}
