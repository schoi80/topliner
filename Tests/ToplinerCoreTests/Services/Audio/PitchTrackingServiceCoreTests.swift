import XCTest
@testable import ToplinerCore

final class PitchTrackingServiceCoreTests: XCTestCase {
    func testMidiNoteNumberMapsA440ToMidi69() {
        XCTAssertEqual(PitchTrackingService.midiNoteNumber(frequency: 440.0), 69)
    }

    func testMidiNoteNumberMapsMiddleCToMidi60() {
        XCTAssertEqual(PitchTrackingService.midiNoteNumber(frequency: 261.63), 60)
    }

    func testTrackObservationsAppliesAmplitudeNoiseGate() {
        let service = PitchTrackingService(amplitudeThreshold: 0.1)
        let observations = [
            PitchObservation(timestamp: 0.0, frequency: 440.0, amplitude: 0.09),
            PitchObservation(timestamp: 0.1, frequency: 440.0, amplitude: 0.1),
            PitchObservation(timestamp: 0.2, frequency: 493.88, amplitude: 0.6)
        ]

        let samples = service.track(observations: observations)

        XCTAssertEqual(samples.count, 2)
        XCTAssertEqual(samples.map(\.timestamp), [0.1, 0.2])
        XCTAssertEqual(samples.map(\.midiNote), [69, 71])
    }

    func testTrackObservationsDropsInvalidFrequencySamples() {
        let service = PitchTrackingService(amplitudeThreshold: 0.1)
        let observations = [
            PitchObservation(timestamp: 0.0, frequency: 0.0, amplitude: 0.8),
            PitchObservation(timestamp: 0.1, frequency: -440.0, amplitude: 0.8),
            PitchObservation(timestamp: 0.2, frequency: 440.0, amplitude: 0.8)
        ]

        let samples = service.track(observations: observations)

        XCTAssertEqual(samples, [
            PitchSample(timestamp: 0.2, frequency: 440.0, midiNote: 69, amplitude: 0.8)
        ])
    }

    func testTrackBufferEstimatesSustainedSineWavePitch() {
        let sampleRate = 44_100.0
        let samples = makeSineWave(frequency: 440.0, seconds: 0.2, sampleRate: sampleRate, amplitude: 0.8)
        let buffer = CapturedAudioBuffer(samples: samples, sampleRate: sampleRate)
        let service = PitchTrackingService(amplitudeThreshold: 0.1, analysisWindowSize: 2_048, analysisHopSize: 2_048)

        let trace = service.track(buffer: buffer)

        XCTAssertFalse(trace.isEmpty)
        XCTAssertTrue(trace.allSatisfy { $0.midiNote == 69 })
        XCTAssertEqual(trace.first?.timestamp ?? -1, 0.0, accuracy: 0.000_1)
    }

    func testTrackBufferDropsQuietWindows() {
        let buffer = CapturedAudioBuffer(samples: Array(repeating: 0.01, count: 4_096), sampleRate: 44_100)
        let service = PitchTrackingService(amplitudeThreshold: 0.1, analysisWindowSize: 2_048, analysisHopSize: 2_048)

        XCTAssertEqual(service.track(buffer: buffer), [])
    }

    private func makeSineWave(
        frequency: Double,
        seconds: Double,
        sampleRate: Double,
        amplitude: Float
    ) -> [Float] {
        let count = Int(seconds * sampleRate)
        return (0..<count).map { index in
            let phase = 2.0 * Double.pi * frequency * Double(index) / sampleRate
            return Float(sin(phase)) * amplitude
        }
    }
}
