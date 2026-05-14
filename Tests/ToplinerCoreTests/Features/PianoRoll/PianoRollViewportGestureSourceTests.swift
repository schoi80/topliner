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

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
