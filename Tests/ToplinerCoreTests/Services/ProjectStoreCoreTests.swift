import XCTest
@testable import ToplinerCore

final class ProjectStoreCoreTests: XCTestCase {
    func testSaveWritesProjectJSONAndLoadRoundTripsDocument() throws {
        let store = try makeStore()
        let project = ProjectDocument(title: "Hook Idea", bpm: 104, key: "A")

        try store.save(project)
        let loaded = try store.load(id: project.id)

        XCTAssertEqual(loaded.title, "Hook Idea")
        XCTAssertEqual(loaded.bpm, 104)
        XCTAssertEqual(loaded.key, "A")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(for: project.id).path))
    }

    func testListReturnsProjectsSortedByUpdatedAtDescending() throws {
        let store = try makeStore()
        let older = ProjectDocument(title: "Older", updatedAt: Date(timeIntervalSince1970: 10))
        let newer = ProjectDocument(title: "Newer", updatedAt: Date(timeIntervalSince1970: 20))

        try store.save(older)
        try store.save(newer)

        XCTAssertEqual(try store.list().map(\.title), ["Newer", "Older"])
    }

    func testDeleteRemovesProjectFile() throws {
        let store = try makeStore()
        let project = ProjectDocument(title: "Delete Me")
        try store.save(project)

        try store.delete(id: project.id)

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: project.id).path))
        XCTAssertThrowsError(try store.load(id: project.id))
    }

    func testDuplicateCreatesNewIdentifierAndCopyTitle() throws {
        let store = try makeStore()
        let original = ProjectDocument(title: "Verse", bpm: 96, key: "D")
        try store.save(original)

        let duplicate = try store.duplicate(id: original.id)

        XCTAssertNotEqual(duplicate.id, original.id)
        XCTAssertEqual(duplicate.title, "Verse Copy")
        XCTAssertEqual(duplicate.bpm, original.bpm)
        XCTAssertEqual(duplicate.key, original.key)
        XCTAssertEqual(try store.list().count, 2)
    }

    func testProjectBrowserFiltersProjectsBySearchQuery() throws {
        let store = try makeStore()
        try store.save(ProjectDocument(title: "Neon Hook", bpm: 96, key: "C"))
        try store.save(ProjectDocument(title: "Ballad Draft", bpm: 72, key: "F"))
        let viewModel = ProjectBrowserViewModel(store: store)

        viewModel.searchQuery = "neon"

        XCTAssertEqual(viewModel.filteredProjects.map(\.title), ["Neon Hook"])
    }

    func testProjectBrowserSelectsFirstProjectAfterRefresh() throws {
        let store = try makeStore()
        let project = ProjectDocument(title: "Selected", updatedAt: Date(timeIntervalSince1970: 20))
        try store.save(project)
        let viewModel = ProjectBrowserViewModel(store: store)

        XCTAssertEqual(viewModel.selectedProject?.id, project.id)
    }

    func testProjectBrowserCreatesAndDeletesProjectsThroughStore() throws {
        let store = try makeStore()
        let viewModel = ProjectBrowserViewModel(store: store)

        try viewModel.createProject(title: "New Song")
        XCTAssertEqual(viewModel.projects.map(\.title), ["New Song"])

        guard let id = viewModel.projects.first?.id else {
            return XCTFail("Expected created project")
        }
        try viewModel.deleteProject(id: id)
        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    private func makeStore() throws -> ProjectStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return ProjectStore(directory: directory)
    }
}
