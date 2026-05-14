import Foundation

struct MIDIFileExporter {
    let ticksPerQuarterNote: Int
    let leadChannel: Int
    let chordChannel: Int

    init(ticksPerQuarterNote: Int = 480, leadChannel: Int = 0, chordChannel: Int = 1) {
        self.ticksPerQuarterNote = max(1, ticksPerQuarterNote)
        self.leadChannel = Self.clamp(leadChannel, lower: 0, upper: 15)
        self.chordChannel = Self.clamp(chordChannel, lower: 0, upper: 15)
    }

    func export(
        leadNotes: [MIDINoteEvent],
        chordProgression: ChordProgression?,
        bpm: Double
    ) throws -> Data {
        var data = Data()
        data.appendASCII("MThd")
        data.appendUInt32(6)
        data.appendUInt16(1)
        data.appendUInt16(3)
        data.appendUInt16(UInt16(ticksPerQuarterNote))

        data.append(trackChunk(conductorEvents(bpm: bpm)))
        data.append(trackChunk(noteEvents(from: leadNotes, channel: leadChannel)))
        data.append(trackChunk(chordEvents(from: chordProgression?.chords ?? [], channel: chordChannel)))
        return data
    }

    func writeExportFile(
        leadNotes: [MIDINoteEvent],
        chordProgression: ChordProgression?,
        bpm: Double,
        fileName: String = "Topliner Export.mid",
        directory: URL = FileManager.default.temporaryDirectory
    ) throws -> URL {
        let data = try export(leadNotes: leadNotes, chordProgression: chordProgression, bpm: bpm)
        let url = directory.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic])
        return url
    }

    private func conductorEvents(bpm: Double) -> [MIDITrackEvent] {
        let clampedBPM = max(1, bpm)
        let microsecondsPerQuarter = Int((60_000_000 / clampedBPM).rounded())
        let tempoPayload = [
            UInt8((microsecondsPerQuarter >> 16) & 0xFF),
            UInt8((microsecondsPerQuarter >> 8) & 0xFF),
            UInt8(microsecondsPerQuarter & 0xFF)
        ]
        return [
            MIDITrackEvent(tick: 0, bytes: [0xFF, 0x51, 0x03] + tempoPayload),
            MIDITrackEvent(tick: 0, bytes: [0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08])
        ]
    }

    private func noteEvents(from notes: [MIDINoteEvent], channel: Int) -> [MIDITrackEvent] {
        notes.flatMap { note in
            let pitch = Self.midiValue(note.pitch)
            let velocity = Self.midiValue(note.velocity)
            let startTick = tick(forBeat: note.startBeat)
            let endTick = tick(forBeat: note.startBeat + max(0, note.durationBeats))
            return [
                MIDITrackEvent(tick: startTick, priority: 0, bytes: [0x90 | UInt8(channel), UInt8(pitch), UInt8(velocity)]),
                MIDITrackEvent(tick: endTick, priority: 1, bytes: [0x80 | UInt8(channel), UInt8(pitch), 0])
            ]
        }
    }

    private func chordEvents(from chords: [ChordEvent], channel: Int) -> [MIDITrackEvent] {
        chords.flatMap { chord in
            let startTick = tick(forBeat: chord.startBeat)
            let endTick = tick(forBeat: chord.startBeat + max(0, chord.durationBeats))
            let sortedPitches = chord.midiNotes.sorted()
            let noteOnEvents = sortedPitches.map { pitch in
                MIDITrackEvent(tick: startTick, priority: 0, bytes: [0x90 | UInt8(channel), UInt8(Self.midiValue(pitch)), 90])
            }
            let noteOffEvents = sortedPitches.map { pitch in
                MIDITrackEvent(tick: endTick, priority: 1, bytes: [0x80 | UInt8(channel), UInt8(Self.midiValue(pitch)), 0])
            }
            return noteOnEvents + noteOffEvents
        }
    }

    private func trackChunk(_ events: [MIDITrackEvent]) -> Data {
        var track = Data()
        var currentTick = 0
        for event in events.sorted() {
            track.appendVariableLengthQuantity(event.tick - currentTick)
            track.append(contentsOf: event.bytes)
            currentTick = event.tick
        }
        track.appendVariableLengthQuantity(0)
        track.append(contentsOf: [0xFF, 0x2F, 0x00])

        var chunk = Data()
        chunk.appendASCII("MTrk")
        chunk.appendUInt32(UInt32(track.count))
        chunk.append(track)
        return chunk
    }

    private func tick(forBeat beat: Double) -> Int {
        max(0, Int((beat * Double(ticksPerQuarterNote)).rounded()))
    }

    private static func midiValue(_ value: Int) -> Int {
        clamp(value, lower: 0, upper: 127)
    }

    private static func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}

private struct MIDITrackEvent: Comparable {
    var tick: Int
    var priority: Int = 0
    var bytes: [UInt8]

    static func < (lhs: MIDITrackEvent, rhs: MIDITrackEvent) -> Bool {
        if lhs.tick != rhs.tick { return lhs.tick < rhs.tick }
        if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
        return lhs.bytes.lexicographicallyPrecedes(rhs.bytes)
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendUInt16(_ value: UInt16) {
        append(contentsOf: [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(contentsOf: [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ])
    }

    mutating func appendVariableLengthQuantity(_ value: Int) {
        var buffer = UInt32(Swift.max(0, value)) & 0x0FFFFFFF
        var bytes = [UInt8(buffer & 0x7F)]
        buffer >>= 7
        while buffer > 0 {
            bytes.insert(UInt8((buffer & 0x7F) | 0x80), at: 0)
            buffer >>= 7
        }
        append(contentsOf: bytes)
    }
}
