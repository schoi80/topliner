import Testing
@testable import ToplinerCore

@Suite("Topliner section navigation")
struct ToplinerSectionCoreTests {
    @Test("sections appear in landscape navigation order")
    func testSectionsAppearInLandscapeNavigationOrder() {
        #expect(ToplinerSection.allCases == [.compose, .capture, .projects, .midi])
    }

    @Test("sections expose compact labels and symbols")
    func testSectionsExposeCompactLabelsAndSymbols() {
        #expect(ToplinerSection.compose.title == "Compose")
        #expect(ToplinerSection.capture.systemImage == "mic")
        #expect(ToplinerSection.projects.title == "Projects")
        #expect(ToplinerSection.midi.systemImage == "cable.connector")
    }
}
