import XCTest
@testable import ToplinerCore

final class PianoRollGridMetricsCoreTests: XCTestCase {
    func testGeneratesOneVerticalLinePerBeatIncludingBoundaries() {
        let metrics = PianoRollGridMetrics(totalBeats: 16, beatsPerBar: 4, pitchRange: 60...71)

        let lines = metrics.verticalLines()

        XCTAssertEqual(lines.map(\.beat), Array(0...16).map(Double.init))
    }

    func testMarksBarBoundariesAsMajorVerticalLines() {
        let metrics = PianoRollGridMetrics(totalBeats: 16, beatsPerBar: 4, pitchRange: 60...71)

        let majorBeats = metrics.verticalLines().filter(\.isMajor).map(\.beat)

        XCTAssertEqual(majorBeats, [0, 4, 8, 12, 16])
    }

    func testGeneratesOneHorizontalLanePerPitchIncludingBoundaries() {
        let metrics = PianoRollGridMetrics(totalBeats: 16, beatsPerBar: 4, pitchRange: 60...71)

        let lines = metrics.horizontalLines()

        XCTAssertEqual(lines.map(\.pitch), Array(60...72))
    }

    func testNormalizesVerticalAndHorizontalLinePositions() {
        let metrics = PianoRollGridMetrics(totalBeats: 16, beatsPerBar: 4, pitchRange: 60...71)

        let verticalPositions = metrics.verticalLines().map(\.normalizedX)
        let horizontalPositions = metrics.horizontalLines().map(\.normalizedY)

        XCTAssertEqual(verticalPositions[0], 0, accuracy: 0.0001)
        XCTAssertEqual(verticalPositions[verticalPositions.count - 1], 1, accuracy: 0.0001)
        XCTAssertEqual(horizontalPositions[0], 0, accuracy: 0.0001)
        XCTAssertEqual(horizontalPositions[horizontalPositions.count - 1], 1, accuracy: 0.0001)
    }
}
