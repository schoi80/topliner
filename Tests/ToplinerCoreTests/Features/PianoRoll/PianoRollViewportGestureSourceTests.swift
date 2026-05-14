import Foundation
import Testing

@Suite("Piano roll viewport gesture wiring")
struct PianoRollViewportGestureSourceTests {
    @Test("iOS viewport layer reserves two-finger pan and pinch for viewport navigation")
    func testViewportGestureLayerUsesTwoFingerPanAndPinch() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/PianoRoll/PianoRollViewportGestureLayer.swift"),
            encoding: .utf8
        )

        #expect(content.contains("UIPanGestureRecognizer"))
        #expect(content.contains("minimumNumberOfTouches = 2"))
        #expect(content.contains("maximumNumberOfTouches = 2"))
        #expect(content.contains("UIPinchGestureRecognizer"))
    }

    @Test("viewport gesture host passes one-finger note editing touches through to the roll")
    func testViewportGestureLayerDoesNotStealSingleFingerNoteEditingTouches() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/PianoRoll/PianoRollViewportGestureLayer.swift"),
            encoding: .utf8
        )

        #expect(content.contains("MultiTouchPassthroughView"))
        #expect(content.contains("override func point(inside point: CGPoint, with event: UIEvent?) -> Bool"))
        #expect(content.contains("event?.allTouches?.count ?? 0"))
        #expect(content.contains(">= 2"))
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
