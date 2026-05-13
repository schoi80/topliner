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

    convenience init(
        audioEngine: AudioEnginePlaybackManaging,
        leadPlayback: SequencerPlaybackManaging,
        chordPlayback: SequencerPlaybackManaging,
        bpm: Double,
        totalBeats: Double,
        currentBeat: Double = 0
    ) {
        self.init(
            audioEngine: audioEngine,
            playback: TrackRoutingSequencerPlayback(leadPlayback: leadPlayback, chordPlayback: chordPlayback),
            bpm: bpm,
            totalBeats: totalBeats,
            currentBeat: currentBeat
        )
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

final class TrackRoutingSequencerPlayback: SequencerPlaybackManaging {
    private let leadPlayback: SequencerPlaybackManaging
    private let chordPlayback: SequencerPlaybackManaging

    init(leadPlayback: SequencerPlaybackManaging, chordPlayback: SequencerPlaybackManaging) {
        self.leadPlayback = leadPlayback
        self.chordPlayback = chordPlayback
    }

    func noteOn(pitch: Int, velocity: Int, track: SequencerTrack) {
        playback(for: track).noteOn(pitch: pitch, velocity: velocity, track: track)
    }

    func noteOff(pitch: Int, track: SequencerTrack) {
        playback(for: track).noteOff(pitch: pitch, track: track)
    }

    private func playback(for track: SequencerTrack) -> SequencerPlaybackManaging {
        switch track {
        case .lead: return leadPlayback
        case .chords: return chordPlayback
        }
    }
}
