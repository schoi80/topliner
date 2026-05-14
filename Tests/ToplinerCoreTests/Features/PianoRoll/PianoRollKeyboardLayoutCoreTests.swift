import XCTest
@testable import ToplinerCore

final class PianoRollKeyboardLayoutCoreTests: XCTestCase {
    func testKeyboardRowsFollowVisiblePitchRangeFromTopToBottom() {
        let layout = PianoRollKeyboardLayout(pitchRange: 60...71)

        XCTAssertEqual(layout.rows.map(\.pitch), Array((60...71).reversed()))
        XCTAssertEqual(layout.rows.first?.label, "B4")
        XCTAssertEqual(layout.rows.last?.label, "C4")
    }

    func testKeyboardRowsIdentifyBlackKeys() {
        let layout = PianoRollKeyboardLayout(pitchRange: 60...71)
        let blackLabels = layout.rows.filter(\.isBlackKey).map(\.label)

        XCTAssertEqual(blackLabels, ["A#4", "G#4", "F#4", "D#4", "C#4"])
    }

    func testKeyboardRowsNormalizeToPianoRollLanes() {
        let layout = PianoRollKeyboardLayout(pitchRange: 60...71)

        XCTAssertEqual(layout.rows.first?.normalizedY ?? -1, 0, accuracy: 0.0001)
        XCTAssertEqual(layout.rows.first?.normalizedHeight ?? -1, 1.0 / 12.0, accuracy: 0.0001)
        XCTAssertEqual(layout.rows.last?.normalizedY ?? -1, 11.0 / 12.0, accuracy: 0.0001)
    }
}
