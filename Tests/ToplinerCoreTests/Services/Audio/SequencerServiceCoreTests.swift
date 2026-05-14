import XCTest
@testable import ToplinerCore

final class SequencerServiceCoreTests: XCTestCase {
    func testConvertsBeatsToSecondsUsingBPM() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 120, loopBeats: 16)

        XCTAssertEqual(sequencer.seconds(forBeats: 4), 2, accuracy: 0.0001)
    }

    func testScheduleCreatesSortedLeadNoteOnAndOffEvents() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 120, loopBeats: 16)
        let note = MIDINoteEvent(pitch: 64, startBeat: 1.5, durationBeats: 0.75, velocity: 96)

        sequencer.schedule(leadNotes: [note])

        XCTAssertEqual(sequencer.scheduledEvents, [
            SequencerEvent(beat: 1.5, kind: .noteOn, pitch: 64, velocity: 96, track: .lead),
            SequencerEvent(beat: 2.25, kind: .noteOff, pitch: 64, velocity: 0, track: .lead)
        ])
    }

    func testScheduleCreatesEventsForEveryChordToneOnChordTrack() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 120, loopBeats: 16)
        let chord = ChordEvent(
            symbol: "Cmaj7",
            rootMidiNote: 60,
            midiNotes: [60, 64, 67, 71],
            startBeat: 4,
            durationBeats: 2,
            romanNumeral: "Imaj7",
            confidence: 0.9
        )

        sequencer.schedule(leadNotes: [], chordProgression: ChordProgression(styleID: "neo-soul", key: "C", chords: [chord]))

        XCTAssertEqual(sequencer.scheduledEvents.filter { $0.kind == .noteOn }.map(\.pitch), [60, 64, 67, 71])
        XCTAssertEqual(sequencer.scheduledEvents.filter { $0.kind == .noteOff }.map(\.pitch), [60, 64, 67, 71])
        XCTAssertTrue(sequencer.scheduledEvents.filter { $0.kind == .noteOn }.allSatisfy { $0.beat == 4 && $0.velocity == 90 && $0.track == .chords })
        XCTAssertTrue(sequencer.scheduledEvents.filter { $0.kind == .noteOff }.allSatisfy { $0.beat == 6 && $0.track == .chords })
    }

    func testAdvanceTriggersEventsBetweenPreviousAndCurrentBeat() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 60, loopBeats: 16)
        sequencer.schedule(leadNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)])

        sequencer.start()
        sequencer.advance(elapsedSeconds: 0.5)
        sequencer.advance(elapsedSeconds: 0.5)

        XCTAssertEqual(sequencer.currentBeat, 1, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [
            .noteOn(pitch: 60, velocity: 100, track: .lead),
            .noteOff(pitch: 60, track: .lead)
        ])
    }

    func testAdvanceLoopsRegionAndTriggersWrappedEvents() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 60, loopBeats: 4, currentBeat: 3.25)
        sequencer.schedule(leadNotes: [
            MIDINoteEvent(pitch: 60, startBeat: 3.5, durationBeats: 0.25, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 0.5, velocity: 80)
        ])

        sequencer.start()
        sequencer.advance(elapsedSeconds: 1)

        XCTAssertEqual(sequencer.currentBeat, 0.25, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [
            .noteOn(pitch: 60, velocity: 100, track: .lead),
            .noteOff(pitch: 60, track: .lead),
            .noteOn(pitch: 64, velocity: 80, track: .lead)
        ])
    }

    func testLoopWrapTurnsOffActiveNotesBeforeRestartingAtLoopStart() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 60, loopBeats: 4, currentBeat: 3.25)
        sequencer.schedule(leadNotes: [
            MIDINoteEvent(pitch: 67, startBeat: 3.5, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 0.5, velocity: 80)
        ])

        sequencer.start()
        sequencer.advance(elapsedSeconds: 1)

        XCTAssertEqual(sequencer.currentBeat, 0.25, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [
            .noteOn(pitch: 67, velocity: 100, track: .lead),
            .noteOff(pitch: 67, track: .lead),
            .noteOn(pitch: 60, velocity: 80, track: .lead)
        ])
    }

    func testLoopWrapTurnsOffChordTrackNotesBeforeRestartingAtLoopStart() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 60, loopBeats: 4, currentBeat: 2.75)
        let chord = ChordEvent(
            symbol: "Cmaj7",
            rootMidiNote: 60,
            midiNotes: [60, 64],
            startBeat: 3,
            durationBeats: 2,
            romanNumeral: "Imaj7",
            confidence: 0.9
        )
        sequencer.schedule(
            leadNotes: [],
            chordProgression: ChordProgression(styleID: "neo-soul", key: "C", chords: [chord])
        )

        sequencer.start()
        sequencer.advance(elapsedSeconds: 1.5)

        XCTAssertEqual(sequencer.currentBeat, 0.25, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [
            .noteOn(pitch: 60, velocity: 90, track: .chords),
            .noteOn(pitch: 64, velocity: 90, track: .chords),
            .noteOff(pitch: 60, track: .chords),
            .noteOff(pitch: 64, track: .chords)
        ])
    }

    func testScheduleAddsMetronomeClickEventsWhenEnabled() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 120, loopBeats: 4)

        sequencer.schedule(leadNotes: [], chordProgression: nil, metronomeEnabled: true)

        XCTAssertEqual(sequencer.scheduledEvents, [
            SequencerEvent(beat: 0, kind: .noteOn, pitch: 84, velocity: 110, track: .metronome),
            SequencerEvent(beat: 0.08, kind: .noteOff, pitch: 84, velocity: 0, track: .metronome),
            SequencerEvent(beat: 1, kind: .noteOn, pitch: 76, velocity: 84, track: .metronome),
            SequencerEvent(beat: 1.08, kind: .noteOff, pitch: 76, velocity: 0, track: .metronome),
            SequencerEvent(beat: 2, kind: .noteOn, pitch: 76, velocity: 84, track: .metronome),
            SequencerEvent(beat: 2.08, kind: .noteOff, pitch: 76, velocity: 0, track: .metronome),
            SequencerEvent(beat: 3, kind: .noteOn, pitch: 76, velocity: 84, track: .metronome),
            SequencerEvent(beat: 3.08, kind: .noteOff, pitch: 76, velocity: 0, track: .metronome)
        ])
    }

    func testStopTurnsOffActivePitches() {
        let playback = MockSequencerPlayback()
        let sequencer = SequencerService(playback: playback, bpm: 60, loopBeats: 4)
        sequencer.schedule(leadNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 2, velocity: 100)])

        sequencer.start()
        sequencer.advance(elapsedSeconds: 0.25)
        sequencer.stop()

        XCTAssertFalse(sequencer.isPlaying)
        XCTAssertEqual(playback.events, [
            .noteOn(pitch: 60, velocity: 100, track: .lead),
            .noteOff(pitch: 60, track: .lead)
        ])
    }
}

private final class MockSequencerPlayback: SequencerPlaybackManaging {
    enum Event: Equatable {
        case noteOn(pitch: Int, velocity: Int, track: SequencerTrack)
        case noteOff(pitch: Int, track: SequencerTrack)
    }

    private(set) var events: [Event] = []

    func noteOn(pitch: Int, velocity: Int, track: SequencerTrack) {
        events.append(.noteOn(pitch: pitch, velocity: velocity, track: track))
    }

    func noteOff(pitch: Int, track: SequencerTrack) {
        events.append(.noteOff(pitch: pitch, track: track))
    }
}
