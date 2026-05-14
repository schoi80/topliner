import XCTest

final class ToplinerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
    }

    func testAppLaunchesIntoComposerWorkspace() throws {
        XCTAssertTrue(app.descendants(matching: .any)["topliner.screen.compose"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["TOPLINER"].exists)
    }

    func testTopNavigationButtonsSwitchScreens() throws {
        assertTapSwitchesScreen(buttonID: "topliner.nav.capture", screenID: "topliner.screen.capture")
        assertTapSwitchesScreen(buttonID: "topliner.nav.projects", screenID: "topliner.screen.projects")
        assertTapSwitchesScreen(buttonID: "topliner.nav.midi", screenID: "topliner.screen.midi")
        assertTapSwitchesScreen(buttonID: "topliner.nav.compose", screenID: "topliner.screen.compose")
    }

    func testMIDIEditorPrimaryControlsAreVisibleAndHittableInLandscape() throws {
        assertTapSwitchesScreen(buttonID: "topliner.nav.midi", screenID: "topliner.screen.midi")

        let requiredButtons = [
            "topliner.midi.route.both",
            "topliner.midi.route.lead",
            "topliner.midi.route.chords",
            "topliner.midi.route.muted",
            "topliner.midi.test-note",
            "topliner.midi.bluetooth.pair"
        ]

        for buttonID in requiredButtons {
            let button = app.buttons[buttonID]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing MIDI control \(buttonID)")
            XCTAssertTrue(button.isHittable, "MIDI control \(buttonID) is not hittable")
        }

        let networkToggle = app.switches["topliner.midi.network.enable"]
        XCTAssertTrue(networkToggle.waitForExistence(timeout: 5), "Missing Network MIDI enable switch")
        XCTAssertTrue(networkToggle.isHittable, "Network MIDI enable switch is not hittable")

        app.buttons["topliner.midi.route.lead"].tap()
        XCTAssertTrue(app.staticTexts["Lead"].waitForExistence(timeout: 2))
    }

    func testComposerPianoRollHasOneOctaveKeyboardAtRightEdge() throws {
        XCTAssertTrue(app.descendants(matching: .any)["topliner.screen.compose"].waitForExistence(timeout: 5))

        let requiredKeys = ["C4", "F#4", "B4"]
        for key in requiredKeys {
            let keyButtons = app.buttons.matching(identifier: key)
            let keyButton = keyButtons.element(boundBy: 0)
            XCTAssertTrue(keyButton.waitForExistence(timeout: 5), "Missing piano key \(key)")
            XCTAssertTrue(keyButton.isHittable, "Piano key \(key) is not hittable")
        }

        let c4Buttons = app.buttons.matching(identifier: "C4")
        let rightmostC4MaxX = (0..<c4Buttons.count)
            .map { c4Buttons.element(boundBy: $0).frame.maxX }
            .max() ?? 0
        XCTAssertTrue(rightmostC4MaxX > app.windows.element(boundBy: 0).frame.midX, "Piano key strip should sit on the right side of the piano roll workspace")
        XCTAssertEqual(app.buttons.matching(identifier: "C5").count, 0, "One-octave viewport must not expose a second C above B4")
    }

    private func assertTapSwitchesScreen(buttonID: String, screenID: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[buttonID]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing button \(buttonID)", file: file, line: line)
        XCTAssertTrue(button.isHittable, "Button \(buttonID) is not hittable", file: file, line: line)

        button.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)[screenID].waitForExistence(timeout: 5),
            "Expected screen \(screenID) after tapping \(buttonID)",
            file: file,
            line: line
        )
    }
}
