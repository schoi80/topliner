import XCTest

final class ToplinerUITests: XCTestCase {
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Topliner"].waitForExistence(timeout: 5))
    }
}
