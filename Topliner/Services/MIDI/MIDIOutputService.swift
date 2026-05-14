import Foundation
#if canImport(CoreMIDI)
import CoreMIDI
#endif

protocol MIDIPacketSending: AnyObject {
    func send(packet: [UInt8]) throws
}

enum MIDIOutputRoute: Equatable {
    case lead
    case chords
    case both
}

enum MIDIOutputServiceError: Error, Equatable {
    case packetTooShort
}

final class MIDIOutputService {
    private let sink: MIDIPacketSending
    private(set) var activePitches: Set<Int> = []
    let channel: Int

    init(sink: MIDIPacketSending = CoreMIDIPacketSink(), channel: Int = 0) {
        self.sink = sink
        self.channel = Self.clamp(channel, lower: 0, upper: 15)
    }

    func noteOn(pitch: Int, velocity: Int) throws {
        let midiPitch = Self.midiValue(pitch)
        let midiVelocity = Self.midiValue(velocity)
        try sink.send(packet: [0x90 | UInt8(channel), UInt8(midiPitch), UInt8(midiVelocity)])
        if midiVelocity > 0 {
            activePitches.insert(midiPitch)
        }
    }

    func noteOff(pitch: Int) throws {
        let midiPitch = Self.midiValue(pitch)
        try sink.send(packet: [0x80 | UInt8(channel), UInt8(midiPitch), 0])
        activePitches.remove(midiPitch)
    }

    func sendChord(_ chord: ChordEvent, velocity: Int = 90) throws {
        for pitch in chord.midiNotes {
            try noteOn(pitch: pitch, velocity: velocity)
        }
    }

    func send(
        leadNotes: [MIDINoteEvent],
        chordProgression: ChordProgression?,
        route: MIDIOutputRoute
    ) throws {
        if route == .lead || route == .both {
            for note in leadNotes.sorted(by: sortLeadNotes) {
                try noteOn(pitch: note.pitch, velocity: note.velocity)
            }
        }

        if route == .chords || route == .both {
            for chord in chordProgression?.chords.sorted(by: sortChords) ?? [] {
                try sendChord(chord)
            }
        }
    }

    func allNotesOff() throws {
        for pitch in activePitches.sorted() {
            try noteOff(pitch: pitch)
        }
    }

    private func sortLeadNotes(_ lhs: MIDINoteEvent, _ rhs: MIDINoteEvent) -> Bool {
        if lhs.startBeat != rhs.startBeat { return lhs.startBeat < rhs.startBeat }
        return lhs.pitch < rhs.pitch
    }

    private func sortChords(_ lhs: ChordEvent, _ rhs: ChordEvent) -> Bool {
        if lhs.startBeat != rhs.startBeat { return lhs.startBeat < rhs.startBeat }
        return lhs.symbol < rhs.symbol
    }

    private static func midiValue(_ value: Int) -> Int {
        clamp(value, lower: 0, upper: 127)
    }

    private static func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}

final class CoreMIDIPacketSink: MIDIPacketSending {
    #if canImport(CoreMIDI)
    private var client = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var destination: MIDIEndpointRef?
    #endif

    init(destination: MIDIEndpointRef? = nil) {
        #if canImport(CoreMIDI)
        self.destination = destination
        MIDIClientCreate("Topliner MIDI Client" as CFString, nil, nil, &client)
        MIDIOutputPortCreate(client, "Topliner MIDI Output" as CFString, &outputPort)
        #endif
    }

    func send(packet: [UInt8]) throws {
        guard packet.count >= 3 else { throw MIDIOutputServiceError.packetTooShort }
        #if canImport(CoreMIDI)
        // Destination routing is configured by later MIDI settings tasks. Until then, the
        // service still creates a Core MIDI client/output port and safely no-ops without
        // a selected destination while tests exercise packet formation through a fake sink.
        guard let destination, destination != 0 else { return }
        var bytes = packet
        bytes.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            let packetListPointer = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
            defer { packetListPointer.deallocate() }
            var packet = MIDIPacketListInit(packetListPointer)
            packet = MIDIPacketListAdd(
                packetListPointer,
                1024,
                packet,
                0,
                buffer.count,
                baseAddress
            )
            MIDISend(outputPort, destination, packetListPointer)
        }
        #endif
    }
}
