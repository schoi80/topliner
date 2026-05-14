import Foundation
import Testing

@Suite("App orientation configuration")
struct AppOrientationConfigurationTests {
    @Test("Info plist declares landscape-only full-screen support")
    func testInfoPlistDeclaresLandscapeOnlyFullScreenSupport() throws {
        let plistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Topliner/Info.plist")
        let data = try Data(contentsOf: plistURL)
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

        let orientations = try #require(plist["UISupportedInterfaceOrientations"] as? [String])
        let iPadOrientations = try #require(plist["UISupportedInterfaceOrientations~ipad"] as? [String])

        #expect(orientations == ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"])
        #expect(iPadOrientations == orientations)
        #expect(plist["UIRequiresFullScreen"] as? Bool == true)
        #expect(plist["UIStatusBarHidden"] as? Bool == true)
        #expect(plist["UIViewControllerBasedStatusBarAppearance"] as? Bool == false)
    }

    @Test("project targets iPad as a native full-screen device family")
    func testProjectTargetsIPadAsNativeFullScreenDeviceFamily() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectYAML = try String(contentsOf: root.appendingPathComponent("project.yml"), encoding: .utf8)

        #expect(projectYAML.contains("TARGETED_DEVICE_FAMILY: \"1,2\""))
    }
}
