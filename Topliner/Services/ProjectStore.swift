import Foundation

enum ProjectStoreError: Error, Equatable {
    case missingProject(UUID)
}

final class ProjectStore {
    let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL = ProjectStore.defaultDirectory()) {
        self.directory = directory
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Projects", isDirectory: true)
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("ToplinerProjects", isDirectory: true)
    }

    func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("topliner.json")
    }

    func save(_ project: ProjectDocument) throws {
        try ensureDirectoryExists()
        var copy = project
        copy.updatedAt = Date()
        let data = try encoder.encode(copy)
        try data.write(to: fileURL(for: copy.id), options: [.atomic])
    }

    func load(id: UUID) throws -> ProjectDocument {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProjectStoreError.missingProject(id)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(ProjectDocument.self, from: data)
    }

    func list() throws -> [ProjectDocument] {
        try ensureDirectoryExists()
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        return try urls
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasSuffix(".topliner.json") }
            .map { try decoder.decode(ProjectDocument.self, from: Data(contentsOf: $0)) }
            .sorted { lhs, rhs in
                if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
                return lhs.title < rhs.title
            }
    }

    @discardableResult
    func duplicate(id: UUID) throws -> ProjectDocument {
        let original = try load(id: id)
        let now = Date()
        var duplicate = original
        duplicate.id = UUID()
        duplicate.title = "\(original.title) Copy"
        duplicate.createdAt = now
        duplicate.updatedAt = now
        try save(duplicate)
        return try load(id: duplicate.id)
    }

    func delete(id: UUID) throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProjectStoreError.missingProject(id)
        }
        try FileManager.default.removeItem(at: url)
    }

    private func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
