import XCTest
@testable import ToplinerCore

final class MIDIOutputServiceCoreTests: XCTestCase {
    func testNoteOnSendsMidiNoteOnPacket() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink, channel: 0)

        try service.noteOn(pitch: 60, velocity: 100)

        XCTAssertEqual(sink.packets, [[0x90, 60, 100]])
    }

    func testNoteOffSendsMidiNoteOffPacket() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink, channel: 2)

        try service.noteOff(pitch: 64)

        XCTAssertEqual(sink.packets, [[0x82, 64, 0]])
    }

    func testValuesAreClampedToMidiRange() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink, channel: 20)

        try service.noteOn(pitch: 200, velocity: -4)

        XCTAssertEqual(service.channel, 15)
        XCTAssertEqual(sink.packets, [[0x9F, 127, 0]])
    }

    func testSendChordSendsEveryChordToneWithSharedVelocity() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink)
        let chord = ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [60, 64, 67], startBeat: 0, durationBeats: 4)

        try service.sendChord(chord, velocity: 88)

        XCTAssertEqual(sink.packets, [[0x90, 60, 88], [0x90, 64, 88], [0x90, 67, 88]])
    }

    func testAllNotesOffSendsNoteOffForActivePitches() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink)
        try service.noteOn(pitch: 67, velocity: 90)
        try service.noteOn(pitch: 60, velocity: 90)

        try service.allNotesOff()

        XCTAssertEqual(sink.packets.suffix(2), [[0x80, 60, 0], [0x80, 67, 0]])
        XCTAssertTrue(service.activePitches.isEmpty)
    }

    func testRouteLeadOnlySendsLeadNotes() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink)
        let lead = [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 91)]
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [
            ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [60, 64, 67], startBeat: 0, durationBeats: 4)
        ])

        try service.send(leadNotes: lead, chordProgression: progression, route: .lead)

        XCTAssertEqual(sink.packets, [[0x90, 60, 91]])
    }

    func testRouteChordsOnlySendsChordNotes() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink)
        let lead = [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 91)]
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [
            ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [48, 52, 55], startBeat: 0, durationBeats: 4)
        ])

        try service.send(leadNotes: lead, chordProgression: progression, route: .chords)

        XCTAssertEqual(sink.packets, [[0x90, 48, 90], [0x90, 52, 90], [0x90, 55, 90]])
    }

    func testRouteBothSendsLeadAndChordNotes() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink)
        let lead = [MIDINoteEvent(pitch: 72, startBeat: 0, durationBeats: 1, velocity: 80)]
        let progression = ChordProgression(styleID: "neo_soul", key: "C", chords: [
            ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [48], startBeat: 0, durationBeats: 4)
        ])

        try service.send(leadNotes: lead, chordProgression: progression, route: .both)

        XCTAssertEqual(sink.packets, [[0x90, 72, 80], [0x90, 48, 90]])
    }
}

private final class RecordingMIDIPacketSink: MIDIPacketSending {
    var packets: [[UInt8]] = []

    func send(packet: [UInt8]) throws {
        packets.append(packet)
    }
}
