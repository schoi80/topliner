import XCTest
@testable import ToplinerCore

final class MIDISettingsLayoutCoreTests: XCTestCase {
    func testIPadMiniLandscapeUsesThreeCompactColumns() {
        let layout = MIDISettingsLandscapeLayout(availableWidth: 1_024, availableHeight: 744)

        XCTAssertEqual(layout.columnCount, 3)
        XCTAssertEqual(layout.contentColumns.map(\.panel), [.routing, .bluetooth, .network])
        XCTAssertGreaterThanOrEqual(layout.contentColumns.map(\.width).min() ?? 0, 260)
    }

    func testCompactLandscapeBudgetAvoidsDefaultTallNavigationLayout() {
        let layout = MIDISettingsLandscapeLayout(availableWidth: 1_024, availableHeight: 744)

        XCTAssertLessThanOrEqual(layout.estimatedContentHeight, 620)
        XCTAssertEqual(layout.verticalSpacing, 10)
        XCTAssertEqual(layout.panelPadding, 12)
    }

    func testNarrowLandscapeFallsBackToTwoColumnsWithoutShrinkingTouchTargets() {
        let layout = MIDISettingsLandscapeLayout(availableWidth: 760, availableHeight: 540)

        XCTAssertEqual(layout.columnCount, 2)
        XCTAssertGreaterThanOrEqual(layout.minimumControlHeight, StudioLayout.minimumTouchTarget)
        XCTAssertGreaterThanOrEqual(layout.contentColumns.map(\.width).min() ?? 0, 260)
    }
}
