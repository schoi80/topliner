import Foundation
import Observation

@Observable
final class ComposerPlaybackController {
    private let audioEngine: AudioEnginePlaybackManaging
    private let sequencer: SequencerService
    private let previewPlayback: SequencerPlaybackManaging

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
        self.previewPlayback = playback
        sequencer = SequencerService(playback: playback, bpm: bpm, loopBeats: totalBeats, currentBeat: currentBeat)
        self.currentBeat = currentBeat
        isPlaying = false
        lastErrorMessage = nil
    }

    convenience init(
        audioEngine: AudioEnginePlaybackManaging,
        leadPlayback: SequencerPlaybackManaging,
        chordPlayback: SequencerPlaybackManaging,
        metronomePlayback: SequencerPlaybackManaging? = nil,
        bpm: Double,
        totalBeats: Double,
        currentBeat: Double = 0
    ) {
        let routedPlayback = TrackRoutingSequencerPlayback(
            leadPlayback: leadPlayback,
            chordPlayback: chordPlayback,
            metronomePlayback: metronomePlayback
        )
        self.init(
            audioEngine: audioEngine,
            playback: routedPlayback,
            bpm: bpm,
            totalBeats: totalBeats,
            currentBeat: currentBeat
        )
    }

    func start(leadNotes: [MIDINoteEvent], chordProgression: ChordProgression? = nil, metronomeEnabled: Bool = false) throws {
        guard !isPlaying else { return }

        do {
            try audioEngine.start()
            sequencer.schedule(leadNotes: leadNotes, chordProgression: chordProgression, metronomeEnabled: metronomeEnabled)
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

    func previewKeyboardPitch(_ pitch: Int, velocity: Int = 96) throws {
        do {
            try audioEngine.start()
            previewPlayback.noteOn(
                pitch: min(max(pitch, 0), 127),
                velocity: min(max(velocity, 0), 127),
                track: .lead
            )
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func stopPreviewKeyboardPitch(_ pitch: Int) {
        previewPlayback.noteOff(pitch: min(max(pitch, 0), 127), track: .lead)
    }

    func preview(note: MIDINoteEvent) throws -> Double {
        try previewKeyboardPitch(note.pitch, velocity: note.velocity)
        guard bpm > 0 else { return 0 }
        return max(0, note.durationBeats) * 60 / bpm
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
    private let metronomePlayback: SequencerPlaybackManaging

    init(
        leadPlayback: SequencerPlaybackManaging,
        chordPlayback: SequencerPlaybackManaging,
        metronomePlayback: SequencerPlaybackManaging? = nil
    ) {
        self.leadPlayback = leadPlayback
        self.chordPlayback = chordPlayback
        self.metronomePlayback = metronomePlayback ?? leadPlayback
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
        case .metronome: return metronomePlayback
        }
    }
}
