import XCTest
@testable import ToplinerCore

final class PromptBuilderCoreTests: XCTestCase {
    func testPromptIncludesMelodyNotesAsStructuredBeatData() {
        let builder = ChordGenerationPromptBuilder()
        let style = HarmonicStyle(
            id: "neo_soul",
            displayName: "Neo-soul",
            promptInstructions: "Use lush extended chords and smooth chromatic passing motion.",
            progressionSeeds: [ProgressionSeed(name: "Turnaround", chords: ["Imaj9", "III7alt", "vi9", "V13sus"])]
        )
        let request = ChordGenerationRequest(
            styleID: style.id,
            key: "C",
            bpm: 92,
            melodyNotes: [
                MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 0.5, velocity: 96),
                MIDINoteEvent(pitch: 64, startBeat: 1.25, durationBeats: 0.75, velocity: 84)
            ],
            totalBeats: 8
        )

        let prompt = builder.buildPrompt(request: request, style: style)

        XCTAssertTrue(prompt.contains("\"melodyNotes\""))
        XCTAssertTrue(prompt.contains("\"pitch\": 60"))
        XCTAssertTrue(prompt.contains("\"startBeat\": 0"))
        XCTAssertTrue(prompt.contains("\"durationBeats\": 0.5"))
        XCTAssertTrue(prompt.contains("\"velocity\": 96"))
        XCTAssertTrue(prompt.contains("\"pitch\": 64"))
        XCTAssertTrue(prompt.contains("\"startBeat\": 1.25"))
    }

    func testPromptIncludesStyleInstructionsAndSeedProgressions() {
        let builder = ChordGenerationPromptBuilder()
        let style = HarmonicStyle(
            id: "gospel_rnb",
            displayName: "Gospel R&B",
            promptInstructions: "Use secondary dominants, diminished passing chords, and rich 7th/9th voicings.",
            progressionSeeds: [
                ProgressionSeed(name: "Walkdown", chords: ["Imaj7", "viiø7", "iii7", "vi7"]),
                ProgressionSeed(name: "Amen", chords: ["IVmaj7", "V13", "Imaj9"])
            ]
        )
        let request = ChordGenerationRequest(styleID: style.id, key: "F", bpm: 76, melodyNotes: [], totalBeats: 16)

        let prompt = builder.buildPrompt(request: request, style: style)

        XCTAssertTrue(prompt.contains("Gospel R&B"))
        XCTAssertTrue(prompt.contains("Use secondary dominants"))
        XCTAssertTrue(prompt.contains("Walkdown"))
        XCTAssertTrue(prompt.contains("Imaj7"))
        XCTAssertTrue(prompt.contains("Amen"))
        XCTAssertTrue(prompt.contains("V13"))
    }

    func testPromptDemandsJsonOnly() {
        let builder = ChordGenerationPromptBuilder()
        let style = HarmonicStyle(
            id: "synthwave",
            displayName: "Synthwave",
            promptInstructions: "Use nostalgic minor-key loops.",
            progressionSeeds: [ProgressionSeed(name: "Loop", chords: ["i", "bVI", "bIII", "bVII"])]
        )
        let request = ChordGenerationRequest(styleID: style.id, key: "A", bpm: 118, melodyNotes: [], totalBeats: 4)

        let prompt = builder.buildPrompt(request: request, style: style)

        XCTAssertTrue(prompt.contains("Return JSON only"))
        XCTAssertTrue(prompt.contains("Do not include Markdown"))
        XCTAssertTrue(prompt.contains("Do not include prose"))
    }

    func testPromptIncludesPreviousProgressionAndRegenerationInstructions() throws {
        let style = HarmonicStyle(
            id: "neo_soul",
            displayName: "Neo-soul",
            promptInstructions: "Use lush chords.",
            progressionSeeds: []
        )
        let previous = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [ChordEvent(symbol: "Cmaj9", rootMidiNote: 60, midiNotes: [60, 64, 67, 71, 74], startBeat: 0, durationBeats: 4, romanNumeral: "Imaj9", confidence: 0.9)],
            explanation: "Previous"
        )
        let request = ChordGenerationRequest(
            styleID: style.id,
            key: "C",
            bpm: 120,
            melodyNotes: [],
            totalBeats: 16,
            complexity: .advanced,
            previousProgression: previous,
            variantIndex: 1
        )

        let prompt = ChordGenerationPromptBuilder().buildPrompt(request: request, style: style)

        XCTAssertTrue(prompt.contains("previousProgression"))
        XCTAssertTrue(prompt.contains("Cmaj9"))
        XCTAssertTrue(prompt.contains("Generate a meaningfully different variant"))
        XCTAssertTrue(prompt.contains("passing chords"))
        XCTAssertTrue(prompt.contains("turnaround chords"))
        XCTAssertTrue(prompt.contains("secondary dominants"))
        XCTAssertTrue(prompt.contains("neighbor chords"))
    }

    func testPromptIncludesStrictResponseSchema() {
        let builder = ChordGenerationPromptBuilder()
        let style = HarmonicStyle(
            id: "jazz",
            displayName: "Jazz",
            promptInstructions: "Use functional harmony.",
            progressionSeeds: [ProgressionSeed(name: "ii-V-I", chords: ["ii7", "V7", "Imaj7"])]
        )
        let request = ChordGenerationRequest(styleID: style.id, key: "Bb", bpm: 140, melodyNotes: [], totalBeats: 12)

        let prompt = builder.buildPrompt(request: request, style: style)

        XCTAssertTrue(prompt.contains("\"styleID\": \"jazz\""))
        XCTAssertTrue(prompt.contains("\"key\": \"Bb\""))
        XCTAssertTrue(prompt.contains("\"chords\""))
        XCTAssertTrue(prompt.contains("\"symbol\""))
        XCTAssertTrue(prompt.contains("\"rootMidiNote\""))
        XCTAssertTrue(prompt.contains("\"midiNotes\""))
        XCTAssertTrue(prompt.contains("\"startBeat\""))
        XCTAssertTrue(prompt.contains("\"durationBeats\""))
        XCTAssertTrue(prompt.contains("\"romanNumeral\""))
        XCTAssertTrue(prompt.contains("\"confidence\""))
        XCTAssertTrue(prompt.contains("All startBeat and durationBeats values must align to 0.25-beat grid"))
    }
}
