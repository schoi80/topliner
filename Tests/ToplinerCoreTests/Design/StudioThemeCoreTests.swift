import Testing
@testable import ToplinerCore

@Suite("Studio design primitives")
struct StudioThemeCoreTests {
    @Test("transport state formats session controls")
    func testTransportStateFormatsSessionControls() {
        let state = StudioTransportState(
            projectTitle: "Neon Drift",
            bpm: 123.6,
            barLength: 8,
            isMetronomeEnabled: true,
            snapLabel: "1/16"
        )

        #expect(state.bpmLabel == "124 BPM")
        #expect(state.barLengthLabel == "8 bars")
        #expect(state.loopLengthLabel == "32 beats")
        #expect(state.metronomeLabel == "Metro On")
        #expect(state.snapDisplayLabel == "Snap 1/16")
    }

    @Test("transport state clamps display values")
    func testTransportStateClampsDisplayValues() {
        let state = StudioTransportState(
            projectTitle: "Sketch",
            bpm: 12,
            barLength: 24,
            isMetronomeEnabled: false,
            snapLabel: "1/32"
        )

        #expect(state.bpmLabel == "40 BPM")
        #expect(state.barLengthLabel == "16 bars")
        #expect(state.loopLengthLabel == "64 beats")
        #expect(state.metronomeLabel == "Metro Off")
    }

    @Test("studio layout metrics keep touch controls large enough")
    func testStudioLayoutMetricsKeepTouchControlsLargeEnough() {
        #expect(StudioLayout.minimumTransportHeight >= 56)
        #expect(StudioLayout.minimumToolbarHeight >= 56)
        #expect(StudioLayout.minimumTouchTarget >= 44)
        #expect(StudioLayout.harmonyPanelWidth >= 240)
    }
}
