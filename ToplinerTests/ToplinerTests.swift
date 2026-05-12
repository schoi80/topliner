import XCTest
@testable import Topliner

final class ToplinerTests: XCTestCase {
    func testAppEnvironmentHasDefaultName() {
        let environment = AppEnvironment()
        XCTAssertEqual(environment.appName, "Topliner")
    }
}
