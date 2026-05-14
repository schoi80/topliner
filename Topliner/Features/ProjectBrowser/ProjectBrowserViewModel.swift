import Foundation
import Observation

@Observable
final class ProjectBrowserViewModel {
    private let store: ProjectStore
    private(set) var projects: [ProjectDocument]
    private(set) var errorMessage: String?
    var searchQuery: String = ""
    var selectedProjectID: UUID?

    var filteredProjects: [ProjectDocument] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return projects }
        return projects.filter { project in
            project.title.localizedCaseInsensitiveContains(query)
                || (project.key?.localizedCaseInsensitiveContains(query) == true)
                || "\(Int(project.bpm))".contains(query)
        }
    }

    var selectedProject: ProjectDocument? {
        guard let selectedProjectID else { return filteredProjects.first }
        return filteredProjects.first { $0.id == selectedProjectID } ?? filteredProjects.first
    }

    init(store: ProjectStore = ProjectStore()) {
        self.store = store
        projects = []
        refresh()
    }

    func refresh() {
        do {
            projects = try store.list()
            if selectedProjectID == nil || projects.contains(where: { $0.id == selectedProjectID }) == false {
                selectedProjectID = projects.first?.id
            }
            errorMessage = nil
        } catch {
            projects = []
            errorMessage = "Could not load projects."
        }
    }

    func createProject(title: String = "Untitled Sketch") throws {
        let project = ProjectDocument(title: title)
        try store.save(project)
        selectedProjectID = project.id
        refresh()
    }

    func selectProject(id: UUID) {
        selectedProjectID = id
    }

    func duplicateProject(id: UUID) throws {
        let duplicate = try store.duplicate(id: id)
        selectedProjectID = duplicate.id
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
