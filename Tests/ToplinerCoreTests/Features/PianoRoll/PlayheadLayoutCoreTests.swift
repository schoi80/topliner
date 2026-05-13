import CoreGraphics
import XCTest
@testable import ToplinerCore

final class PlayheadLayoutCoreTests: XCTestCase {
    func testXPositionMapsCurrentBeatIntoWidth() {
        let layout = PlayheadLayout(currentBeat: 4, totalBeats: 16, width: 400)

        XCTAssertEqual(layout.xPosition, 100, accuracy: 0.0001)
    }

    func testXPositionClampsBelowZeroAndAboveTotalBeats() {
        let belowRange = PlayheadLayout(currentBeat: -1, totalBeats: 16, width: 400)
        let aboveRange = PlayheadLayout(currentBeat: 20, totalBeats: 16, width: 400)

        XCTAssertEqual(belowRange.xPosition, 0, accuracy: 0.0001)
        XCTAssertEqual(aboveRange.xPosition, 400, accuracy: 0.0001)
    }

    func testXPositionReturnsZeroForInvalidDimensions() {
        let zeroBeats = PlayheadLayout(currentBeat: 4, totalBeats: 0, width: 400)
        let zeroWidth = PlayheadLayout(currentBeat: 4, totalBeats: 16, width: 0)

        XCTAssertEqual(zeroBeats.xPosition, 0, accuracy: 0.0001)
        XCTAssertEqual(zeroWidth.xPosition, 0, accuracy: 0.0001)
    }
}
