import Foundation
import Testing

@Suite("App layout policy")
struct AppLayoutPolicyTests {
    @Test("only MIDI settings keeps a scroll container")
    func testOnlyMIDISettingsKeepsScrollContainer() throws {
        let root = repositoryRoot()
        let featureFiles = try swiftFiles(under: root.appendingPathComponent("Topliner/Features"))
        let filesWithScrollContainers = try featureFiles.compactMap { file -> String? in
            let content = try String(contentsOf: file, encoding: .utf8)
            guard content.contains("ScrollView") || content.contains("Form {") || content.contains("List {") else {
                return nil
            }
            return file.path.replacingOccurrences(of: root.path + "/", with: "")
        }

        #expect(filesWithScrollContainers == ["Topliner/Features/MIDISettings/MIDISettingsView.swift"])
    }

    @Test("primary landscape feature screens avoid default Form and List chrome")
    func testPrimaryLandscapeScreensAvoidDefaultFormAndListChrome() throws {
        let root = repositoryRoot()
        let primaryScreens = [
            "Topliner/Features/Composer/ComposerView.swift",
            "Topliner/Features/Capture/AudioCaptureView.swift",
            "Topliner/Features/ProjectBrowser/ProjectBrowserView.swift"
        ]

        for relativePath in primaryScreens {
            let content = try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
            #expect(content.contains("Form {") == false, "\(relativePath) must not use Form chrome")
            #expect(content.contains("List {") == false, "\(relativePath) must not use List chrome")
            #expect(content.contains("ScrollView") == false, "\(relativePath) must not introduce scrolling")
        }
    }

    @Test("decorative studio overlays do not intercept touches")
    func testDecorativeStudioOverlaysDoNotInterceptTouches() throws {
        let root = repositoryRoot()
        let filesWithDecorativeOverlays = [
            "Topliner/Design/StudioControlChip.swift",
            "Topliner/Design/StudioPanel.swift",
            "Topliner/Design/TransportBar.swift",
            "Topliner/Features/Composer/ComposerEditingToolbar.swift",
            "Topliner/Features/Composer/ComposerView.swift"
        ]

        for relativePath in filesWithDecorativeOverlays {
            let content = try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
            #expect(
                content.contains(".allowsHitTesting(false)"),
                "\(relativePath) must mark decorative overlays as non-interactive so buttons remain tappable"
            )
        }
    }

    @Test("root app shell owns full-screen landscape chrome")
    func testRootAppShellOwnsFullScreenLandscapeChrome() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/App/ToplinerAppShell.swift"),
            encoding: .utf8
        )

        #expect(content.contains(".ignoresSafeArea(.container, edges: .all)"))
        #expect(content.contains(".persistentSystemOverlays(.hidden)"))
        #expect(content.contains(".statusBarHidden(true)"))
        #expect(content.contains("NavigationStack { MIDISettingsView() }") == false)
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func swiftFiles(under directory: URL) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
        let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: Array(resourceKeys))
        var files: [URL] = []
        while let file = enumerator?.nextObject() as? URL {
            let values = try file.resourceValues(forKeys: resourceKeys)
            if values.isRegularFile == true && file.pathExtension == "swift" {
                files.append(file)
            }
        }
        return files.sorted { $0.path < $1.path }
    }
}
