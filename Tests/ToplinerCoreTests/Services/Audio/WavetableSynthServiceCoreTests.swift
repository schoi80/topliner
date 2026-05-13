import XCTest
@testable import ToplinerCore

final class WavetableSynthServiceCoreTests: XCTestCase {
    func testDefaultEnvelopeUsesShortMusicalADSR() {
        let envelope = SynthEnvelope.default

        XCTAssertEqual(envelope.attackDuration, 0.01, accuracy: 0.0001)
        XCTAssertEqual(envelope.decayDuration, 0.08, accuracy: 0.0001)
        XCTAssertEqual(envelope.sustainLevel, 0.8, accuracy: 0.0001)
        XCTAssertEqual(envelope.releaseDuration, 0.15, accuracy: 0.0001)
    }

    func testNoteOnStartsVoiceWithMidiFrequencyAndNormalizedVelocity() {
        let voice = MockSynthVoiceManager()
        let service = WavetableSynthService(voice: voice)

        service.noteOn(pitch: 69, velocity: 64)

        XCTAssertEqual(voice.noteOnEvents.count, 1)
        XCTAssertEqual(voice.noteOnEvents[0].pitch, 69)
        XCTAssertEqual(voice.noteOnEvents[0].frequency, 440, accuracy: 0.0001)
        XCTAssertEqual(voice.noteOnEvents[0].amplitude, 64.0 / 127.0, accuracy: 0.0001)
        XCTAssertEqual(service.activePitches, [69])
    }

    func testNoteOnClampsVelocityToMidiRange() {
        let voice = MockSynthVoiceManager()
        let service = WavetableSynthService(voice: voice)

        service.noteOn(pitch: 60, velocity: 200)

        XCTAssertEqual(voice.noteOnEvents[0].amplitude, 1.0, accuracy: 0.0001)
    }

    func testNoteOffStopsVoiceAndClearsActivePitch() {
        let voice = MockSynthVoiceManager()
        let service = WavetableSynthService(voice: voice)

        service.noteOn(pitch: 60, velocity: 100)
        service.noteOff(pitch: 60)

        XCTAssertEqual(voice.noteOffEvents, [60])
        XCTAssertTrue(service.activePitches.isEmpty)
    }

    func testPlayChordStartsEveryChordToneWithSharedVelocity() {
        let voice = MockSynthVoiceManager()
        let service = WavetableSynthService(voice: voice)
        let chord = ChordEvent(
            symbol: "Cmaj7",
            rootMidiNote: 60,
            midiNotes: [60, 64, 67, 71],
            startBeat: 0,
            durationBeats: 4,
            romanNumeral: "Imaj7",
            confidence: 0.95
        )

        service.play(chord: chord, velocity: 90)

        XCTAssertEqual(voice.noteOnEvents.map(\.pitch), [60, 64, 67, 71])
        XCTAssertEqual(service.activePitches, [60, 64, 67, 71])
        XCTAssertTrue(voice.noteOnEvents.allSatisfy { abs($0.amplitude - 90.0 / 127.0) < 0.0001 })
    }
}

private final class MockSynthVoiceManager: SynthVoiceManaging {
    struct NoteOnEvent: Equatable {
        var pitch: Int
        var frequency: Double
        var amplitude: Double
        var envelope: SynthEnvelope
    }

    private(set) var noteOnEvents: [NoteOnEvent] = []
    private(set) var noteOffEvents: [Int] = []

    func noteOn(pitch: Int, frequency: Double, amplitude: Double, envelope: SynthEnvelope) {
        noteOnEvents.append(
            NoteOnEvent(
                pitch: pitch,
                frequency: frequency,
                amplitude: amplitude,
                envelope: envelope
            )
        )
    }

    func noteOff(pitch: Int) {
        noteOffEvents.append(pitch)
    }
}
