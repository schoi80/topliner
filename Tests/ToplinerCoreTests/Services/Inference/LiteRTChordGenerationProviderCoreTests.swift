import XCTest
@testable import ToplinerCore

final class LiteRTChordGenerationProviderCoreTests: XCTestCase {
    func testThrowsClearSetupErrorWhenModelFileIsMissing() throws {
        let library = try StyleLibrary.defaultLibrary()
        let missingURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("litertlm")
        let provider = LiteRTChordGenerationProvider(modelURL: missingURL, styleLibrary: library)
        let request = ChordGenerationRequest(styleID: "neo_soul", key: "C", bpm: 120, melodyNotes: [], totalBeats: 16)

        XCTAssertThrowsError(try provider.generateProgression(for: request)) { error in
            XCTAssertEqual(error as? LiteRTChordGenerationProviderError, .modelFileMissing(missingURL.path))
            XCTAssertTrue(error.localizedDescription.contains("Add a .litertlm model file"))
        }
    }

    func testFactoryFallsBackToMockProviderWhenModelFileIsMissing() throws {
        let library = try StyleLibrary.defaultLibrary()
        let missingURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("litertlm")

        let provider = ChordGenerationProviderFactory.makeDefaultProvider(
            styleLibrary: library,
            modelURL: missingURL,
            preferLiteRT: true
        )
        let request = ChordGenerationRequest(styleID: "neo_soul", key: "C", bpm: 120, melodyNotes: [], totalBeats: 16)

        let progression = try provider.generateProgression(for: request)

        XCTAssertEqual(progression.styleID, "neo_soul")
        XCTAssertFalse(progression.chords.isEmpty)
        XCTAssertTrue(progression.explanation?.contains("Mock progression") == true)
    }

    func testProviderBuildsSymbolicPromptBeforeRuntimeInvocation() throws {
        let library = try StyleLibrary.defaultLibrary()
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("litertlm")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let provider = LiteRTChordGenerationProvider(modelURL: tempURL, styleLibrary: library)
        let request = ChordGenerationRequest(
            styleID: "neo_soul",
            key: "C",
            bpm: 120,
            melodyNotes: [MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100)],
            totalBeats: 16
        )

        XCTAssertThrowsError(try provider.generateProgression(for: request)) { error in
            XCTAssertEqual(error as? LiteRTChordGenerationProviderError, .runtimeUnavailable)
        }
        XCTAssertTrue(provider.lastPrompt?.contains("Response schema:") == true)
        XCTAssertTrue(provider.lastPrompt?.contains("\"melodyNotes\"") == true)
    }

    func testDefaultModelURLPointsAtBundledModelsDirectory() {
        let url = LiteRTChordGenerationProvider.defaultModelURL()

        XCTAssertEqual(url.lastPathComponent, "topliner-chord-model.litertlm")
        XCTAssertTrue(url.path.contains("Models"))
    }
}
