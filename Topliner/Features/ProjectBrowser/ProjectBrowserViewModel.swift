import Foundation
import Observation

@Observable
final class ProjectBrowserViewModel {
    private let store: ProjectStore
    private(set) var projects: [ProjectDocument]
    private(set) var errorMessage: String?

    init(store: ProjectStore = ProjectStore()) {
        self.store = store
        projects = []
        refresh()
    }

    func refresh() {
        do {
            projects = try store.list()
            errorMessage = nil
        } catch {
            projects = []
            errorMessage = "Could not load projects."
        }
    }

    func createProject(title: String = "Untitled Sketch") throws {
        let project = ProjectDocument(title: title)
        try store.save(project)
        refresh()
    }

    func duplicateProject(id: UUID) throws {
        _ = try store.duplicate(id: id)
        refresh()
    }

    func deleteProject(id: UUID) throws {
        try store.delete(id: id)
        refresh()
    }

    func loadProject(id: UUID) throws -> ProjectDocument {
        try store.load(id: id)
    }
}
