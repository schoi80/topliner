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
