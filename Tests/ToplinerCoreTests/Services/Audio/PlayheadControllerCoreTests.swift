import XCTest
@testable import ToplinerCore

final class PlayheadControllerCoreTests: XCTestCase {
    func testStartsStoppedAtBeginning() {
        let controller = PlayheadController(bpm: 120, totalBeats: 16)

        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(controller.currentBeat, 0, accuracy: 0.0001)
    }

    func testStartAndStopTogglePlaybackState() {
        let controller = PlayheadController(bpm: 120, totalBeats: 16)

        controller.start()
        XCTAssertTrue(controller.isPlaying)

        controller.stop()
        XCTAssertFalse(controller.isPlaying)
    }

    func testAdvanceWhilePlayingMovesBeatByTempo() {
        let controller = PlayheadController(bpm: 120, totalBeats: 16)

        controller.start()
        controller.advance(elapsedSeconds: 0.5)

        XCTAssertEqual(controller.currentBeat, 1, accuracy: 0.0001)
    }

    func testAdvanceWhileStoppedDoesNotMoveBeat() {
        let controller = PlayheadController(bpm: 120, totalBeats: 16)

        controller.advance(elapsedSeconds: 0.5)

        XCTAssertEqual(controller.currentBeat, 0, accuracy: 0.0001)
    }

    func testAdvanceWrapsAtTotalBeats() {
        let controller = PlayheadController(bpm: 120, totalBeats: 4)

        controller.start()
        controller.advance(elapsedSeconds: 2.5)

        XCTAssertEqual(controller.currentBeat, 1, accuracy: 0.0001)
    }

    func testResetReturnsToBeginningAndStops() {
        let controller = PlayheadController(bpm: 120, totalBeats: 16)

        controller.start()
        controller.advance(elapsedSeconds: 0.5)
        controller.reset()

        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(controller.currentBeat, 0, accuracy: 0.0001)
    }
}
