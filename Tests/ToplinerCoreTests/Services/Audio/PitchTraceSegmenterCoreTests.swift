import XCTest
@testable import ToplinerCore

final class PitchTraceSegmenterCoreTests: XCTestCase {
    func testSegmentsAdjacentSamePitchSamplesIntoOneQuantizedNote() {
        let segmenter = PitchTraceSegmenter(
            amplitudeThreshold: 0.1,
            maximumMergeGapSeconds: 0.12,
            sampleDurationSeconds: 0.1,
            quantizeGridBeats: 0.25,
            minimumDurationBeats: 0.25,
            defaultVelocity: 96
        )
        let trace = [
            sample(time: 0.00, pitch: 69),
            sample(time: 0.10, pitch: 69),
            sample(time: 0.20, pitch: 69)
        ]

        let notes = segmenter.segment(trace: trace, bpm: 120)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].pitch, 69)
        XCTAssertEqual(notes[0].startBeat, 0.0, accuracy: 0.000_1)
        XCTAssertEqual(notes[0].durationBeats, 0.5, accuracy: 0.000_1)
        XCTAssertEqual(notes[0].velocity, 96)
    }

    func testSplitsWhenPitchChanges() {
        let segmenter = PitchTraceSegmenter(
            amplitudeThreshold: 0.1,
            maximumMergeGapSeconds: 0.12,
            sampleDurationSeconds: 0.1,
            quantizeGridBeats: 0.25,
            minimumDurationBeats: 0.25
        )
        let trace = [
            sample(time: 0.00, pitch: 69),
            sample(time: 0.10, pitch: 69),
            sample(time: 0.20, pitch: 71),
            sample(time: 0.30, pitch: 71)
        ]

        let notes = segmenter.segment(trace: trace, bpm: 120)

        XCTAssertEqual(notes.map(\.pitch), [69, 71])
        XCTAssertEqual(notes.map(\.startBeat), [0.0, 0.5])
        XCTAssertEqual(notes.map(\.durationBeats), [0.5, 0.5])
    }

    func testSplitsSamePitchWhenGapIsTooLarge() {
        let segmenter = PitchTraceSegmenter(
            amplitudeThreshold: 0.1,
            maximumMergeGapSeconds: 0.12,
            sampleDurationSeconds: 0.1,
            quantizeGridBeats: 0.25,
            minimumDurationBeats: 0.25
        )
        let trace = [
            sample(time: 0.00, pitch: 69),
            sample(time: 0.10, pitch: 69),
            sample(time: 0.40, pitch: 69),
            sample(time: 0.50, pitch: 69)
        ]

        let notes = segmenter.segment(trace: trace, bpm: 120)

        XCTAssertEqual(notes.map(\.pitch), [69, 69])
        XCTAssertEqual(notes.map(\.startBeat), [0.0, 0.75])
        XCTAssertEqual(notes.map(\.durationBeats), [0.5, 0.5])
    }

    func testQuietSampleBreaksSegmentAndIsIgnored() {
        let segmenter = PitchTraceSegmenter(
            amplitudeThreshold: 0.1,
            maximumMergeGapSeconds: 0.20,
            sampleDurationSeconds: 0.1,
            quantizeGridBeats: 0.25,
            minimumDurationBeats: 0.25
        )
        let trace = [
            sample(time: 0.00, pitch: 69, amplitude: 0.6),
            sample(time: 0.10, pitch: 69, amplitude: 0.05),
            sample(time: 0.20, pitch: 69, amplitude: 0.6)
        ]

        let notes = segmenter.segment(trace: trace, bpm: 120)

        XCTAssertEqual(notes.map(\.pitch), [69, 69])
        XCTAssertEqual(notes.map(\.startBeat), [0.0, 0.5])
        XCTAssertEqual(notes.map(\.durationBeats), [0.25, 0.25])
    }

    func testDropsVeryShortGhostNotesAfterQuantization() {
        let segmenter = PitchTraceSegmenter(
            amplitudeThreshold: 0.1,
            maximumMergeGapSeconds: 0.12,
            sampleDurationSeconds: 0.03,
            quantizeGridBeats: 0.25,
            minimumDurationBeats: 0.25
        )
        let trace = [
            sample(time: 0.00, pitch: 69),
            sample(time: 0.20, pitch: 71),
            sample(time: 0.30, pitch: 71),
            sample(time: 0.40, pitch: 71)
        ]

        let notes = segmenter.segment(trace: trace, bpm: 120)

        XCTAssertEqual(notes.map(\.pitch), [71])
        XCTAssertEqual(notes[0].startBeat, 0.5)
        XCTAssertEqual(notes[0].durationBeats, 0.5)
    }

    func testInvalidBPMReturnsNoNotes() {
        let segmenter = PitchTraceSegmenter()

        XCTAssertEqual(segmenter.segment(trace: [sample(time: 0.0, pitch: 69)], bpm: 0), [])
    }

    private func sample(time: Double, pitch: Int, amplitude: Double = 0.6) -> PitchSample {
        PitchSample(timestamp: time, frequency: 440.0, midiNote: pitch, amplitude: amplitude)
    }
}
