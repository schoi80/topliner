import Testing
@testable import ToplinerCore

@Suite("Composer harmony panel model")
struct ComposerHarmonyPanelModelCoreTests {
    @Test("empty progression uses generate copy")
    func testEmptyProgressionUsesGenerateCopy() {
        let model = ComposerHarmonyPanelModel(progression: nil as ChordProgression?, isGenerating: false, variantIndex: 0)

        #expect(model.primaryActionTitle == "Generate")
        #expect(model.statusMessage == "No chords yet")
        #expect(model.chordChips.isEmpty)
    }

    @Test("generated progression uses regenerate copy and compact chips")
    func testGeneratedProgressionUsesRegenerateCopyAndCompactChips() {
        let progression = ChordProgression(
            styleID: "neo-soul",
            key: "C",
            chords: [
                ChordEvent(symbol: "Cmaj7", rootMidiNote: 60, midiNotes: [60, 64, 67, 71], startBeat: 0, durationBeats: 4, romanNumeral: "Imaj7"),
                ChordEvent(symbol: "Am7", rootMidiNote: 57, midiNotes: [57, 60, 64, 67], startBeat: 4, durationBeats: 4, romanNumeral: "vi7")
            ],
            explanation: "Test"
        )
        let model = ComposerHarmonyPanelModel(progression: progression, isGenerating: false, variantIndex: 2)

        #expect(model.primaryActionTitle == "Regenerate Variant")
        #expect(model.statusMessage == "Variant 3 · 2 chords")
        #expect(model.chordChips.map(\.symbol) == ["Cmaj7", "Am7"])
        #expect(model.chordChips.map(\.detail) == ["Imaj7", "vi7"])
    }

    @Test("generating state prioritizes working copy")
    func testGeneratingStatePrioritizesWorkingCopy() {
        let model = ComposerHarmonyPanelModel(progression: nil as ChordProgression?, isGenerating: true, variantIndex: 0)

        #expect(model.primaryActionTitle == "Generating…")
        #expect(model.statusMessage == "Listening to melody context")
    }
}
