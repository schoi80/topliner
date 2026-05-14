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

    @Test("composer piano roll uses right-edge keyboard instead of legacy pitch strip")
    func testComposerPianoRollUsesRightEdgeKeyboardInsteadOfLegacyPitchStrip() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerView.swift"),
            encoding: .utf8
        )

        #expect(content.contains("PianoRollView("))
        #expect(content.contains("PianoRollKeyboardStrip") == false)
        #expect(content.contains("pitchRange: 48...84") == false)
    }

    @Test("composer wires keyboard strip to press and release synth preview playback")
    func testComposerWiresKeyboardStripPressAndReleaseToPreviewPlayback() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerView.swift"),
            encoding: .utf8
        )

        #expect(content.contains("onKeyboardKeyDown: previewKeyboardPitch"))
        #expect(content.contains("onKeyboardKeyUp: stopPreviewKeyboardPitch"))
        #expect(content.contains("private func previewKeyboardPitch(_ pitch: Int)"))
        #expect(content.contains("private func stopPreviewKeyboardPitch(_ pitch: Int)"))
        #expect(content.contains("playbackController.previewKeyboardPitch(pitch"))
        #expect(content.contains("playbackController.stopPreviewKeyboardPitch(pitch)"))
    }

    @Test("composer wires existing piano-roll note touches to duration-aware synth preview")
    func testComposerWiresPianoRollNoteTouchesToDurationAwarePreview() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerView.swift"),
            encoding: .utf8
        )

        #expect(content.contains("onNoteTouchDown: previewNote"))
        #expect(content.contains("private func previewNote(_ note: MIDINoteEvent)"))
        #expect(content.contains("let releaseDelay = try playbackController.preview(note: note)"))
        #expect(content.contains("playbackController.stopPreviewKeyboardPitch(note.pitch)"))
    }

    @Test("piano-roll keyboard strip uses drag state for immediate press hold and legato sliding")
    func testKeyboardStripUsesDragStateForImmediatePressHoldAndLegatoSliding() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/PianoRoll/PianoRollKeyboardStrip.swift"),
            encoding: .utf8
        )

        #expect(content.contains("@State private var activePitch"))
        #expect(content.contains("DragGesture(minimumDistance: 0"))
        #expect(content.contains("handleTouch(at: value.location"))
        #expect(content.contains("onKeyDown?(pitch)"))
        #expect(content.contains("onKeyUp?(previousPitch)"))
    }

    @Test("composer transport renders editable tempo loop and metronome controls")
    func testComposerTransportRendersEditableSessionControls() throws {
        let root = repositoryRoot()
        let transportContent = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerTransportView.swift"),
            encoding: .utf8
        )
        let composerContent = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerView.swift"),
            encoding: .utf8
        )

        #expect(transportContent.contains("@Binding var bpm: Double"))
        #expect(transportContent.contains("@Binding var barLength: Int"))
        #expect(transportContent.contains("@Binding var isMetronomeEnabled: Bool"))
        #expect(transportContent.contains("ComposerSessionControlsView("))
        #expect(composerContent.contains("bpm: $viewModel.bpm"))
        #expect(composerContent.contains("barLength: $viewModel.barLength"))
        #expect(composerContent.contains("isMetronomeEnabled: $viewModel.isMetronomeEnabled"))
    }

    @Test("composer keeps playback timing in sync when session settings change")
    func testComposerSyncsPlaybackControllerWhenSessionSettingsChange() throws {
        let root = repositoryRoot()
        let content = try String(
            contentsOf: root.appendingPathComponent("Topliner/Features/Composer/ComposerView.swift"),
            encoding: .utf8
        )

        #expect(content.contains(".onChange(of: viewModel.bpm)"))
        #expect(content.contains("playbackController.bpm = newBPM"))
        #expect(content.contains(".onChange(of: viewModel.totalBeats)"))
        #expect(content.contains("playbackController.totalBeats = newTotalBeats"))
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
