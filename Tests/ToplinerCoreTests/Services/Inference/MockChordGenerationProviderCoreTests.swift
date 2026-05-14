import XCTest
@testable import ToplinerCore

final class MockChordGenerationProviderCoreTests: XCTestCase {
    func testMockReturnsDeterministicProgressionForNeoSoulStyle() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let request = ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: [
                MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 96),
                MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 88)
            ],
            totalBeats: 4
        )

        let progression = try provider.generateProgression(for: request)

        XCTAssertEqual(progression.styleID, "neo_soul")
        XCTAssertEqual(progression.key, "C")
        XCTAssertEqual(progression.chords.map(\.symbol), ["Cmaj9", "E7alt", "Am9", "G13sus"])
        XCTAssertEqual(progression.chords.map(\.startBeat), [0, 1, 2, 3])
        XCTAssertEqual(progression.chords.map(\.durationBeats), [1, 1, 1, 1])
        XCTAssertTrue(progression.explanation?.contains("Mock") == true)
    }

    func testMockReturnsProgressionForEveryDefaultStyle() throws {
        let library = try StyleLibrary.defaultLibrary()
        let provider = MockChordGenerationProvider(styleLibrary: library)

        for style in library.styles {
            let request = ChordGenerationRequest(
                styleID: style.id,
                key: "D",
                bpm: 120,
                melodyNotes: [],
                totalBeats: 8
            )

            let progression = try provider.generateProgression(for: request)

            XCTAssertEqual(progression.styleID, style.id)
            XCTAssertEqual(progression.key, "D")
            XCTAssertFalse(progression.chords.isEmpty, "\(style.id) should produce deterministic mock chords")
            XCTAssertEqual(progression.chords.first?.startBeat, 0)
        }
    }

    func testMockThrowsForUnknownStyle() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let request = ChordGenerationRequest(
            styleID: "unknown_style",
            key: "C",
            bpm: 120,
            melodyNotes: [],
            totalBeats: 4
        )

        XCTAssertThrowsError(try provider.generateProgression(for: request)) { error in
            XCTAssertEqual(error as? ChordGenerationError, .unknownStyle("unknown_style"))
        }
    }

    func testMockVariesProgressionWhenMelodyChanges() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let lowOpening = ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 96)],
            totalBeats: 8,
            complexity: .balanced
        )
        let highOpening = ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: [MIDINoteEvent(pitch: 71, startBeat: 0.5, durationBeats: 1, velocity: 96)],
            totalBeats: 8,
            complexity: .balanced
        )

        let lowProgression = try provider.generateProgression(for: lowOpening)
        let highProgression = try provider.generateProgression(for: highOpening)

        XCTAssertNotEqual(lowProgression.chords.map(\.romanNumeral), highProgression.chords.map(\.romanNumeral))
        XCTAssertNotEqual(lowProgression.chords.map(\.symbol), highProgression.chords.map(\.symbol))
    }

    func testMockComplexityChangesChordDensityAndExtensions() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let melody = [MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 96)]
        let simple = try provider.generateProgression(for: ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: melody,
            totalBeats: 8,
            complexity: .simple
        ))
        let advanced = try provider.generateProgression(for: ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: melody,
            totalBeats: 8,
            complexity: .advanced
        ))

        XCTAssertLessThan(simple.chords.count, advanced.chords.count)
        XCTAssertNotEqual(simple.chords.map(\.symbol), advanced.chords.map(\.symbol))
        XCTAssertTrue(advanced.chords.contains { $0.symbol.contains("9") || $0.symbol.contains("13") || $0.symbol.contains("alt") })
    }

    func testMockRegenerationUsesDifferentVariantThanPreviousProgression() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let baseRequest = ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 96)],
            totalBeats: 8,
            complexity: .balanced
        )
        let first = try provider.generateProgression(for: baseRequest)
        let regenerated = try provider.generateProgression(for: ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: baseRequest.melodyNotes,
            totalBeats: 8,
            complexity: .balanced,
            previousProgression: first,
            variantIndex: 1
        ))

        XCTAssertNotEqual(first.chords.map(\.romanNumeral), regenerated.chords.map(\.romanNumeral))
        XCTAssertTrue(regenerated.explanation?.contains("variant 2") == true)
    }

    func testAdvancedMockAddsPassingTurnaroundSecondaryAndNeighborChords() throws {
        let provider = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let progression = try provider.generateProgression(for: ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 92,
            melodyNotes: [MIDINoteEvent(pitch: 64, startBeat: 0, durationBeats: 1, velocity: 96)],
            totalBeats: 8,
            complexity: .advanced
        ))
        let romans = progression.chords.compactMap(\.romanNumeral)

        XCTAssertGreaterThanOrEqual(progression.chords.count, 8)
        XCTAssertTrue(romans.contains("#ivø7"), "advanced should include passing/neighbor harmonic glue")
        XCTAssertTrue(romans.contains("V7/vi"), "advanced should include secondary dominants")
        XCTAssertTrue(romans.contains("bII7"), "advanced should include turnaround color")
    }

    func testMockUsesSeedChordCountToDistributeDurationsAcrossTotalBeats() throws {
        let style = HarmonicStyle(
            id: "test_style",
            displayName: "Test Style",
            promptInstructions: "Use test harmony.",
            progressionSeeds: [
                ProgressionSeed(name: "Three chords", chords: ["I", "IV", "V"])
            ]
        )
        let provider = MockChordGenerationProvider(styleLibrary: StyleLibrary(styles: [style]))
        let request = ChordGenerationRequest(
            styleID: "test_style",
            key: "E",
            bpm: 100,
            melodyNotes: [],
            totalBeats: 6
        )

        let progression = try provider.generateProgression(for: request)

        XCTAssertEqual(progression.chords.map(\.symbol), ["E", "A", "B"])
        XCTAssertEqual(progression.chords.map(\.startBeat), [0, 2, 4])
        XCTAssertEqual(progression.chords.map(\.durationBeats), [2, 2, 2])
    }

    func testProviderProtocolCanBeUsedAsDependency() throws {
        let provider: ChordGenerationProviding = MockChordGenerationProvider(styleLibrary: try .defaultLibrary())
        let request = ChordGenerationRequest(
            styleID: "synthwave",
            key: "A",
            bpm: 118,
            melodyNotes: [],
            totalBeats: 4
        )

        let progression = try provider.generateProgression(for: request)

        XCTAssertEqual(progression.styleID, "synthwave")
        XCTAssertEqual(progression.chords.map(\.symbol), ["Am", "F", "C", "G"])
    }
}
