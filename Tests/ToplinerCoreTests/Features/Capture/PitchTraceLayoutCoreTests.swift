import CoreGraphics
import XCTest
@testable import ToplinerCore

final class PitchTraceLayoutCoreTests: XCTestCase {
    func testMapsPitchSamplesToGhostBlocksUsingTempoAndPianoRollGeometry() {
        let layout = PitchTraceLayout(
            samples: [
                PitchSample(timestamp: 0.0, frequency: 261.63, midiNote: 60, amplitude: 0.5),
                PitchSample(timestamp: 0.5, frequency: 329.63, midiNote: 64, amplitude: 0.8)
            ],
            bpm: 120,
            sampleDurationSeconds: 0.1,
            geometry: makeGeometry()
        )

        let blocks = layout.drawableBlocks()

        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks[0].rect, CGRect(x: 0, y: 440, width: 5, height: 40))
        XCTAssertEqual(blocks[1].rect, CGRect(x: 25, y: 280, width: 5, height: 40))
        XCTAssertEqual(blocks.map(\.pitch), [60, 64])
    }

    func testFiltersSamplesOutsideVisiblePitchRange() {
        let layout = PitchTraceLayout(
            samples: [
                PitchSample(timestamp: 0.0, frequency: 220, midiNote: 57, amplitude: 0.7),
                PitchSample(timestamp: 0.1, frequency: 261.63, midiNote: 60, amplitude: 0.7),
                PitchSample(timestamp: 0.2, frequency: 880, midiNote: 81, amplitude: 0.7)
            ],
            bpm: 120,
            sampleDurationSeconds: 0.1,
            geometry: makeGeometry()
        )

        let blocks = layout.drawableBlocks()

        XCTAssertEqual(blocks.map(\.pitch), [60])
    }

    func testOpacityScalesWithAmplitudeAndClampsToGhostRange() {
        let layout = PitchTraceLayout(
            samples: [
                PitchSample(timestamp: 0.0, frequency: 261.63, midiNote: 60, amplitude: 0.05),
                PitchSample(timestamp: 0.1, frequency: 261.63, midiNote: 60, amplitude: 0.5),
                PitchSample(timestamp: 0.2, frequency: 261.63, midiNote: 60, amplitude: 2.0)
            ],
            bpm: 120,
            sampleDurationSeconds: 0.1,
            geometry: makeGeometry()
        )

        let opacities = layout.drawableBlocks().map(\.opacity)

        XCTAssertEqual(opacities[0], 0.18, accuracy: 0.0001)
        XCTAssertEqual(opacities[1], 0.35, accuracy: 0.0001)
        XCTAssertEqual(opacities[2], 0.52, accuracy: 0.0001)
    }

    func testInvalidTempoProducesNoBlocks() {
        let layout = PitchTraceLayout(
            samples: [PitchSample(timestamp: 0.0, frequency: 261.63, midiNote: 60, amplitude: 0.7)],
            bpm: 0,
            sampleDurationSeconds: 0.1,
            geometry: makeGeometry()
        )

        XCTAssertEqual(layout.drawableBlocks(), [])
    }

    private func makeGeometry() -> PianoRollGeometry {
        PianoRollGeometry(size: CGSize(width: 400, height: 480), pitchRange: 60...71, totalBeats: 16, quantizeGrid: 0.25)
    }
}
