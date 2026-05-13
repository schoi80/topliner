import Foundation
import Observation

@Observable
final class ComposerPlaybackController {
    private let audioEngine: AudioEnginePlaybackManaging
    private let sequencer: SequencerService

    private(set) var currentBeat: Double
    private(set) var isPlaying: Bool
    private(set) var lastErrorMessage: String?

    var bpm: Double {
        get { sequencer.bpm }
        set { sequencer.bpm = newValue }
    }

    var totalBeats: Double {
        get { sequencer.loopBeats }
        set { sequencer.loopBeats = newValue }
    }

    init(
        audioEngine: AudioEnginePlaybackManaging,
        playback: SequencerPlaybackManaging,
        bpm: Double,
        totalBeats: Double,
        currentBeat: Double = 0
    ) {
        self.audioEngine = audioEngine
        sequencer = SequencerService(playback: playback, bpm: bpm, loopBeats: totalBeats, currentBeat: currentBeat)
        self.currentBeat = currentBeat
        isPlaying = false
        lastErrorMessage = nil
    }

    func start(leadNotes: [MIDINoteEvent], chordProgression: ChordProgression? = nil) throws {
        guard !isPlaying else { return }

        do {
            try audioEngine.start()
            sequencer.schedule(leadNotes: leadNotes, chordProgression: chordProgression)
            sequencer.start()
            currentBeat = sequencer.currentBeat
            isPlaying = sequencer.isPlaying
            lastErrorMessage = nil
        } catch {
            sequencer.stop()
            currentBeat = sequencer.currentBeat
            isPlaying = false
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func stop() {
        sequencer.stop()
        currentBeat = sequencer.currentBeat
        isPlaying = false
    }

    func reset() {
        sequencer.reset()
        currentBeat = sequencer.currentBeat
        isPlaying = false
    }

    func advance(elapsedSeconds: Double) {
        sequencer.advance(elapsedSeconds: elapsedSeconds)
        currentBeat = sequencer.currentBeat
        isPlaying = sequencer.isPlaying
    }
}
