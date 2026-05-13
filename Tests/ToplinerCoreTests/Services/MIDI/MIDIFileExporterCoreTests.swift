import XCTest
@testable import ToplinerCore

final class MIDIFileExporterCoreTests: XCTestCase {
    func testExportsTypeOneMidiHeaderWithThreeTracks() throws {
        let data = try MIDIFileExporter().export(
            leadNotes: [leadNote()],
            chordProgression: progression(),
            bpm: 120
        )

        XCTAssertEqual(Array(data.prefix(4)), ascii("MThd"))
        XCTAssertEqual(readUInt32(data, offset: 4), 6)
        XCTAssertEqual(readUInt16(data, offset: 8), 1)
        XCTAssertEqual(readUInt16(data, offset: 10), 3)
        XCTAssertEqual(readUInt16(data, offset: 12), 480)
    }

    func testIncludesTempoMetadataInConductorTrack() throws {
        let data = try MIDIFileExporter().export(
            leadNotes: [leadNote()],
            chordProgression: progression(),
            bpm: 120
        )

        let bytes = [UInt8](data)
        XCTAssertTrue(bytes.containsSubsequence([0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20]))
    }

    func testExportsLeadNoteOnAndOffEvents() throws {
        let data = try MIDIFileExporter().export(
            leadNotes: [leadNote(pitch: 64, velocity: 100, startBeat: 1, durationBeats: 0.5)],
            chordProgression: nil,
            bpm: 90
        )

        let bytes = [UInt8](data)
        XCTAssertTrue(bytes.containsSubsequence([0x90, 64, 100]))
        XCTAssertTrue(bytes.containsSubsequence([0x80, 64, 0]))
    }

    func testExportsChordTrackWithEveryChordTone() throws {
        let data = try MIDIFileExporter().export(
            leadNotes: [],
            chordProgression: progression(),
            bpm: 120
        )

        let bytes = [UInt8](data)
        XCTAssertTrue(bytes.containsSubsequence([0x91, 60, 90]))
        XCTAssertTrue(bytes.containsSubsequence([0x91, 64, 90]))
        XCTAssertTrue(bytes.containsSubsequence([0x91, 67, 90]))
        XCTAssertTrue(bytes.containsSubsequence([0x81, 60, 0]))
    }

    func testWritesExportFileToRequestedDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = try MIDIFileExporter().writeExportFile(
            leadNotes: [leadNote()],
            chordProgression: progression(),
            bpm: 120,
            fileName: "Sketch.mid",
            directory: directory
        )

        XCTAssertEqual(url.lastPathComponent, "Sketch.mid")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        XCTAssertEqual(Array(data.prefix(4)), ascii("MThd"))
    }

    private func leadNote(
        pitch: Int = 60,
        velocity: Int = 96,
        startBeat: Double = 0,
        durationBeats: Double = 1
    ) -> MIDINoteEvent {
        MIDINoteEvent(pitch: pitch, startBeat: startBeat, durationBeats: durationBeats, velocity: velocity)
    }

    private func progression() -> ChordProgression {
        ChordProgression(
            styleID: "test",
            key: "C",
            chords: [
                ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [60, 64, 67], startBeat: 0, durationBeats: 2, romanNumeral: "I", confidence: 0.9)
            ],
            explanation: nil
        )
    }

    private func ascii(_ string: String) -> [UInt8] {
        Array(string.utf8)
    }

    private func readUInt16(_ data: Data, offset: Int) -> UInt16 {
        let bytes = [UInt8](data[offset..<(offset + 2)])
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }

    private func readUInt32(_ data: Data, offset: Int) -> UInt32 {
        let bytes = [UInt8](data[offset..<(offset + 4)])
        return UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
    }
}

private extension Array where Element == UInt8 {
    func containsSubsequence(_ subsequence: [UInt8]) -> Bool {
        guard !subsequence.isEmpty, count >= subsequence.count else { return false }
        return indices.dropLast(subsequence.count - 1).contains { index in
            Array(self[index..<(index + subsequence.count)]) == subsequence
        }
    }
}
