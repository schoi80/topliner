import Foundation
import Observation

enum SequencerTrack: Equatable {
    case lead
    case chords
}

protocol SequencerPlaybackManaging: AnyObject {
    func noteOn(pitch: Int, velocity: Int, track: SequencerTrack)
    func noteOff(pitch: Int, track: SequencerTrack)
}

enum SequencerEventKind: Equatable {
    case noteOn
    case noteOff
}

struct SequencerEvent: Equatable {
    var beat: Double
    var kind: SequencerEventKind
    var pitch: Int
    var velocity: Int
    var track: SequencerTrack = .lead
}

@Observable
final class SequencerService {
    private let playback: SequencerPlaybackManaging
    private(set) var scheduledEvents: [SequencerEvent]
    private(set) var activePitches: Set<Int>

    var bpm: Double
    var loopBeats: Double
    var currentBeat: Double
    private(set) var isPlaying: Bool

    init(
        playback: SequencerPlaybackManaging,
        bpm: Double,
        loopBeats: Double,
        currentBeat: Double = 0,
        isPlaying: Bool = false
    ) {
        self.playback = playback
        self.bpm = bpm
        self.loopBeats = loopBeats
        self.currentBeat = currentBeat
        self.isPlaying = isPlaying
        scheduledEvents = []
        activePitches = []
    }

    func seconds(forBeats beats: Double) -> Double {
        guard bpm > 0 else { return 0 }
        return beats * 60 / bpm
    }

    func schedule(leadNotes: [MIDINoteEvent], chordProgression: ChordProgression? = nil) {
        var events: [SequencerEvent] = []

        for note in leadNotes {
            events.append(
                SequencerEvent(
                    beat: note.startBeat,
                    kind: .noteOn,
                    pitch: note.pitch,
                    velocity: note.velocity,
                    track: .lead
                )
            )
            events.append(
                SequencerEvent(
                    beat: note.endBeat,
                    kind: .noteOff,
                    pitch: note.pitch,
                    velocity: 0,
                    track: .lead
                )
            )
        }

        for chord in chordProgression?.chords ?? [] {
            for pitch in chord.midiNotes {
                events.append(
                    SequencerEvent(
                        beat: chord.startBeat,
                        kind: .noteOn,
                        pitch: pitch,
                        velocity: 90,
                        track: .chords
                    )
                )
                events.append(
                    SequencerEvent(
                        beat: chord.startBeat + chord.durationBeats,
                        kind: .noteOff,
                        pitch: pitch,
                        velocity: 0,
                        track: .chords
                    )
                )
            }
        }

        scheduledEvents = events.sorted(by: Self.sortEvents)
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        triggerEvents(at: currentBeat)
    }

    func stop() {
        guard isPlaying else { return }
        activePitches.sorted().forEach { key in
            playback.noteOff(pitch: Self.pitch(fromActivePitchKey: key), track: Self.track(fromActivePitchKey: key))
        }
        activePitches.removeAll()
        isPlaying = false
    }

    func reset() {
        stop()
        currentBeat = 0
    }

    func advance(elapsedSeconds: Double) {
        guard isPlaying, elapsedSeconds > 0, bpm > 0 else { return }
        guard loopBeats > 0 else {
            currentBeat = 0
            return
        }

        let previousBeat = currentBeat
        let beatDelta = elapsedSeconds * bpm / 60
        let unwrappedBeat = previousBeat + beatDelta
        let nextBeat = wrappedBeat(unwrappedBeat)

        triggerEventsCrossing(from: previousBeat, toUnwrappedBeat: unwrappedBeat, wrappedBeat: nextBeat)
        currentBeat = nextBeat
    }

    private func triggerEventsCrossing(from previousBeat: Double, toUnwrappedBeat unwrappedBeat: Double, wrappedBeat nextBeat: Double) {
        if unwrappedBeat < loopBeats {
            triggerEvents(after: previousBeat, through: unwrappedBeat)
        } else {
            triggerEvents(after: previousBeat, beforeLoopEnd: loopBeats)
            triggerEvents(fromLoopStartThrough: nextBeat)
        }
    }

    private func triggerEvents(after lowerBound: Double, through upperBound: Double) {
        scheduledEvents
            .filter { $0.beat > lowerBound && $0.beat <= upperBound }
            .forEach(trigger)
    }

    private func triggerEvents(after lowerBound: Double, beforeLoopEnd loopEnd: Double) {
        scheduledEvents
            .filter { $0.beat > lowerBound && $0.beat < loopEnd }
            .forEach(trigger)
    }

    private func triggerEvents(fromLoopStartThrough upperBound: Double) {
        scheduledEvents
            .filter { $0.beat >= 0 && $0.beat <= upperBound }
            .forEach(trigger)
    }

    private func triggerEvents(at beat: Double) {
        scheduledEvents
            .filter { $0.beat == beat }
            .forEach(trigger)
    }

    private func trigger(_ event: SequencerEvent) {
        switch event.kind {
        case .noteOn:
            playback.noteOn(pitch: event.pitch, velocity: event.velocity, track: event.track)
            activePitches.insert(Self.activePitchKey(pitch: event.pitch, track: event.track))
        case .noteOff:
            playback.noteOff(pitch: event.pitch, track: event.track)
            activePitches.remove(Self.activePitchKey(pitch: event.pitch, track: event.track))
        }
    }

    private func wrappedBeat(_ beat: Double) -> Double {
        let wrapped = beat.truncatingRemainder(dividingBy: loopBeats)
        return wrapped >= 0 ? wrapped : wrapped + loopBeats
    }

    private static func sortEvents(_ lhs: SequencerEvent, _ rhs: SequencerEvent) -> Bool {
        if lhs.beat != rhs.beat { return lhs.beat < rhs.beat }
        if lhs.kind != rhs.kind { return lhs.kind == .noteOff }
        if lhs.pitch != rhs.pitch { return lhs.pitch < rhs.pitch }
        if lhs.track != rhs.track { return lhs.track == .chords }
        return lhs.velocity < rhs.velocity
    }

    private static func activePitchKey(pitch: Int, track: SequencerTrack) -> Int {
        pitch + (track == .chords ? 1_000 : 0)
    }

    private static func pitch(fromActivePitchKey key: Int) -> Int {
        key >= 1_000 ? key - 1_000 : key
    }

    private static func track(fromActivePitchKey key: Int) -> SequencerTrack {
        key >= 1_000 ? .chords : .lead
    }
}

extension WavetableSynthService: SequencerPlaybackManaging {}
