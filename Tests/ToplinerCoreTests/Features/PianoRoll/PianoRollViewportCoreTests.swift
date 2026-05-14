import CoreGraphics
import XCTest
@testable import ToplinerCore

final class PianoRollViewportCoreTests: XCTestCase {
    func testDefaultViewportShowsOneOctaveAndFullPhrase() {
        let viewport = PianoRollViewport.default(totalBeats: 16)

        XCTAssertEqual(viewport.visiblePitchRange, 60...71)
        XCTAssertEqual(viewport.visiblePitchCount, 12)
        XCTAssertEqual(viewport.startBeat, 0, accuracy: 0.0001)
        XCTAssertEqual(viewport.visibleBeats, 16, accuracy: 0.0001)
        XCTAssertEqual(viewport.endBeat, 16, accuracy: 0.0001)
    }

    func testViewportNeverShowsMoreThanOneOctave() {
        let viewport = PianoRollViewport(
            startBeat: 0,
            visibleBeats: 16,
            centerPitch: 66,
            visiblePitchCount: 37,
            totalBeats: 16
        )

        XCTAssertEqual(viewport.visiblePitchCount, 12)
        XCTAssertEqual(viewport.visiblePitchRange.count, 12)
    }

    func testVerticalPanMovesPitchWindowAndClampsToMidiBounds() {
        let viewport = PianoRollViewport.default(totalBeats: 16)
            .panned(beatsDelta: 0, pitchDelta: 12)

        XCTAssertEqual(viewport.visiblePitchRange, 72...83)

        let high = viewport.panned(beatsDelta: 0, pitchDelta: 100)
        XCTAssertEqual(high.visiblePitchRange, 116...127)

        let low = viewport.panned(beatsDelta: 0, pitchDelta: -200)
        XCTAssertEqual(low.visiblePitchRange, 0...11)
    }

    func testHorizontalPanMovesBeatWindowAndClampsToPhraseBounds() {
        let viewport = PianoRollViewport(
            startBeat: 4,
            visibleBeats: 8,
            centerPitch: 65,
            visiblePitchCount: 12,
            totalBeats: 16
        )

        XCTAssertEqual(viewport.panned(beatsDelta: 2, pitchDelta: 0).startBeat, 6, accuracy: 0.0001)
        XCTAssertEqual(viewport.panned(beatsDelta: -20, pitchDelta: 0).startBeat, 0, accuracy: 0.0001)
        XCTAssertEqual(viewport.panned(beatsDelta: 20, pitchDelta: 0).startBeat, 8, accuracy: 0.0001)
    }

    func testPinchZoomChangesTimeAxisAroundAnchorAndKeepsOneOctave() {
        let viewport = PianoRollViewport.default(totalBeats: 16)
        let zoomed = viewport.zoomedTime(by: 2, anchorUnit: 0.5)

        XCTAssertEqual(zoomed.visibleBeats, 8, accuracy: 0.0001)
        XCTAssertEqual(zoomed.startBeat, 4, accuracy: 0.0001)
        XCTAssertEqual(zoomed.visiblePitchRange, 60...71)

        let zoomedOut = zoomed.zoomedTime(by: 0.1, anchorUnit: 0.5)
        XCTAssertEqual(zoomedOut.visibleBeats, 16, accuracy: 0.0001)
        XCTAssertEqual(zoomedOut.startBeat, 0, accuracy: 0.0001)
    }

    func testPixelPanConvertsCanvasTranslationToBeatAndPitchDeltas() {
        let viewport = PianoRollViewport(
            startBeat: 4,
            visibleBeats: 8,
            centerPitch: 65,
            visiblePitchCount: 12,
            totalBeats: 16
        )
        let panned = viewport.pannedByPixels(
            CGSize(width: -100, height: -120),
            canvasSize: CGSize(width: 400, height: 480)
        )

        XCTAssertEqual(panned.startBeat, 6, accuracy: 0.0001)
        XCTAssertEqual(panned.visiblePitchRange, 63...74)
    }
}
