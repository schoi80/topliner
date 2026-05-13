import XCTest
@testable import ToplinerCore

final class ComposerPlaybackControllerCoreTests: XCTestCase {
    func testStartConfiguresAudioEngineSchedulesLeadNotesAndTriggersBeatZeroNote() throws {
        let engine = RecordingPlaybackAudioEngine()
        let playback = RecordingSequencerPlayback()
        let controller = ComposerPlaybackController(audioEngine: engine, playback: playback, bpm: 120, totalBeats: 16)
        let notes = [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 88)
        ]

        try controller.start(leadNotes: notes)

        XCTAssertTrue(engine.didStart)
        XCTAssertTrue(controller.isPlaying)
        XCTAssertEqual(controller.currentBeat, 0, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [.noteOn(60, 100)])
    }

    func testAdvanceMovesPlayheadAndTriggersLaterLeadNotes() throws {
        let engine = RecordingPlaybackAudioEngine()
        let playback = RecordingSequencerPlayback()
        let controller = ComposerPlaybackController(audioEngine: engine, playback: playback, bpm: 120, totalBeats: 16)
        let notes = [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 0.5, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 88)
        ]
        try controller.start(leadNotes: notes)

        controller.advance(elapsedSeconds: 0.5)

        XCTAssertEqual(controller.currentBeat, 1, accuracy: 0.0001)
        XCTAssertEqual(playback.events, [.noteOn(60, 100), .noteOff(60), .noteOn(64, 88)])
    }

    func testStopTurnsOffActiveNotesAndStopsPlaybackState() throws {
        let engine = RecordingPlaybackAudioEngine()
        let playback = RecordingSequencerPlayback()
        let controller = ComposerPlaybackController(audioEngine: engine, playback: playback, bpm: 120, totalBeats: 16)
        let notes = [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100)]
        try controller.start(leadNotes: notes)

        controller.stop()

        XCTAssertFalse(controller.isPlaying)
        XCTAssertEqual(playback.events, [.noteOn(60, 100), .noteOff(60)])
    }

    func testStartSurfacesAudioEngineErrorAndDoesNotStartSequencer() {
        let engine = RecordingPlaybackAudioEngine(startError: PlaybackTestError.engineFailed)
        let playback = RecordingSequencerPlayback()
        let controller = ComposerPlaybackController(audioEngine: engine, playback: playback, bpm: 120, totalBeats: 16)

        XCTAssertThrowsError(try controller.start(leadNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)]))
        XCTAssertFalse(controller.isPlaying)
        XCTAssertTrue(playback.events.isEmpty)
        XCTAssertEqual(controller.lastErrorMessage, PlaybackTestError.engineFailed.localizedDescription)
    }
}

private final class RecordingPlaybackAudioEngine: AudioEnginePlaybackManaging {
    private(set) var isRunning = false
    private(set) var didStart = false
    let startError: Error?

    init(startError: Error? = nil) {
        self.startError = startError
    }

    func start() throws {
        if let startError { throw startError }
        didStart = true
        isRunning = true
    }

    func stop() {
        isRunning = false
    }
}

private final class RecordingSequencerPlayback: SequencerPlaybackManaging {
    enum Event: Equatable {
        case noteOn(Int, Int)
        case noteOff(Int)
    }

    private(set) var events: [Event] = []

    func noteOn(pitch: Int, velocity: Int) {
        events.append(.noteOn(pitch, velocity))
    }

    func noteOff(pitch: Int) {
        events.append(.noteOff(pitch))
    }
}

private enum PlaybackTestError: LocalizedError {
    case engineFailed

    var errorDescription: String? { "engine failed" }
}
