import XCTest
@testable import ToplinerCore

final class ChordGenerationViewModelCoreTests: XCTestCase {
    func testInitialStateSelectsFirstStyleAndBalancedComplexity() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: RecordingChordProvider())

        XCTAssertEqual(viewModel.selectedStyleID, styleLibrary.styles.first?.id)
        XCTAssertEqual(viewModel.selectedComplexity, .balanced)
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertNil(viewModel.generatedProgression)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testGenerateBuildsRequestAndStoresProgression() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let expectedProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [ChordEvent(symbol: "Cmaj9", rootMidiNote: 60, midiNotes: [60, 64, 67, 71, 74], startBeat: 0, durationBeats: 4)],
            explanation: "Generated"
        )
        let provider = RecordingChordProvider(result: expectedProgression)
        let melody = [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)]
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: provider)

        viewModel.selectedStyleID = "neo_soul"
        viewModel.selectedComplexity = .advanced
        viewModel.generateChords(melodyNotes: melody, key: "C", bpm: 120, totalBeats: 16)

        XCTAssertEqual(provider.requests, [
            ChordGenerationRequest(styleID: "neo_soul", key: "C", bpm: 120, melodyNotes: melody, totalBeats: 16, complexity: .advanced)
        ])
        XCTAssertEqual(viewModel.generatedProgression, expectedProgression)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testGenerateStoresFriendlyErrorAndClearsPreviousResult() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let previousProgression = ChordProgression(styleID: "neo_soul", key: "C", chords: [ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [60, 64, 67], startBeat: 0, durationBeats: 4)], explanation: nil)
        let provider = RecordingChordProvider(error: ChordGenerationError.unknownStyle("missing"))
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: provider)
        viewModel.generatedProgression = previousProgression
        viewModel.selectedStyleID = "missing"

        viewModel.generateChords(melodyNotes: [], key: "C", bpm: 120, totalBeats: 16)

        XCTAssertNil(viewModel.generatedProgression)
        XCTAssertEqual(viewModel.errorMessage, "Unknown style: missing")
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testStyleLookupReflectsSelectedStyle() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: RecordingChordProvider())

        viewModel.selectedStyleID = "city_pop"

        XCTAssertEqual(viewModel.selectedStyle?.id, "city_pop")
        XCTAssertEqual(viewModel.availableStyles.map(\.id), styleLibrary.styles.map(\.id))
    }

    func testChordLaneSummaryFormatsGeneratedProgression() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: RecordingChordProvider())
        viewModel.generatedProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [
                ChordEvent(symbol: "Cmaj9", rootMidiNote: 60, midiNotes: [60], startBeat: 0, durationBeats: 4),
                ChordEvent(symbol: "Am9", rootMidiNote: 69, midiNotes: [69], startBeat: 4, durationBeats: 4)
            ],
            explanation: nil
        )

        XCTAssertEqual(viewModel.chordLaneSummary, "Cmaj9 · Am9")
    }

    func testGeneratedChordNotesExpandChordTonesForPianoRollOverlay() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: RecordingChordProvider())
        viewModel.generatedProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [
                ChordEvent(
                    symbol: "Cmaj7",
                    rootMidiNote: 60,
                    midiNotes: [60, 64, 67, 71],
                    startBeat: 4,
                    durationBeats: 2,
                    romanNumeral: "Imaj7",
                    confidence: 0.9
                )
            ],
            explanation: nil
        )

        XCTAssertEqual(viewModel.generatedChordNotes.map(\.pitch), [60, 64, 67, 71])
        XCTAssertEqual(viewModel.generatedChordNotes.map(\.startBeat), [4, 4, 4, 4])
        XCTAssertEqual(viewModel.generatedChordNotes.map(\.durationBeats), [2, 2, 2, 2])
        XCTAssertEqual(viewModel.generatedChordNotes.map(\.velocity), [82, 82, 82, 82])
    }

    func testGenerateRequestIncludesSelectedComplexity() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let provider = RecordingChordProvider()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: provider)

        viewModel.selectedComplexity = .simple
        viewModel.generateChords(melodyNotes: [], key: "C", bpm: 120, totalBeats: 16)

        XCTAssertEqual(provider.requests.last?.complexity, .simple)
    }

    func testRegenerateIncludesPreviousProgressionAndIncrementsVariantIndex() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let firstProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [ChordEvent(symbol: "Cmaj9", rootMidiNote: 60, midiNotes: [60, 64, 67, 71, 74], startBeat: 0, durationBeats: 4)],
            explanation: "First"
        )
        let secondProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [ChordEvent(symbol: "Fmaj9", rootMidiNote: 65, midiNotes: [65, 69, 72, 76, 79], startBeat: 0, durationBeats: 4)],
            explanation: "Second"
        )
        let provider = RecordingChordProvider(results: [firstProgression, secondProgression])
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: provider)

        viewModel.generateChords(melodyNotes: [], key: "C", bpm: 120, totalBeats: 16)
        viewModel.generateChords(melodyNotes: [], key: "C", bpm: 120, totalBeats: 16)

        XCTAssertNil(provider.requests[0].previousProgression)
        XCTAssertEqual(provider.requests[0].variantIndex, 0)
        XCTAssertEqual(provider.requests[1].previousProgression, firstProgression)
        XCTAssertEqual(provider.requests[1].variantIndex, 1)
        XCTAssertEqual(viewModel.generatedProgression, secondProgression)
    }

    func testClearGeneratedChordsRemovesProgressionOverlayAndErrors() throws {
        let styleLibrary = try StyleLibrary.defaultLibrary()
        let viewModel = ChordGenerationViewModel(styleLibrary: styleLibrary, provider: RecordingChordProvider())
        viewModel.generatedProgression = ChordProgression(
            styleID: "neo_soul",
            key: "C",
            chords: [ChordEvent(symbol: "C", rootMidiNote: 60, midiNotes: [60, 64, 67], startBeat: 0, durationBeats: 4)],
            explanation: nil
        )
        viewModel.errorMessage = "Previous error"

        viewModel.clearGeneratedChords()

        XCTAssertNil(viewModel.generatedProgression)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.generatedChordNotes.isEmpty)
        XCTAssertNil(viewModel.chordLaneSummary)
    }
}

private final class RecordingChordProvider: ChordGenerationProviding {
    var requests: [ChordGenerationRequest] = []
    var result: ChordProgression
    var results: [ChordProgression]
    var error: Error?

    init(
        result: ChordProgression = ChordProgression(styleID: "neo_soul", key: "C", chords: [], explanation: nil),
        results: [ChordProgression] = [],
        error: Error? = nil
    ) {
        self.result = result
        self.results = results
        self.error = error
    }

    func generateProgression(for request: ChordGenerationRequest) throws -> ChordProgression {
        requests.append(request)
        if let error { throw error }
        if requests.count <= results.count { return results[requests.count - 1] }
        return result
    }
}
