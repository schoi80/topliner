import Foundation

struct HarmonicStyle: Codable, Equatable, Identifiable {
    var id: String
    var displayName: String
    var promptInstructions: String
    var progressionSeeds: [ProgressionSeed]
}

struct ProgressionSeed: Codable, Equatable {
    var name: String
    var chords: [String]
}

enum StyleLibraryError: Error, Equatable {
    case resourceNotFound(String)
    case duplicateStyleID(String)
    case emptyStyleID
    case emptyProgressionSeeds(String)
    case emptyPromptInstructions(String)
}

struct StyleLibrary: Codable, Equatable {
    var styles: [HarmonicStyle]

    static func defaultLibrary() throws -> StyleLibrary {
        let resourceName = "harmonic_styles"
        guard let url = defaultResourceBundle.url(forResource: resourceName, withExtension: "json") else {
            throw StyleLibraryError.resourceNotFound("\(resourceName).json")
        }

        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    static func decode(_ data: Data) throws -> StyleLibrary {
        let library = try JSONDecoder().decode(StyleLibrary.self, from: data)
        try library.validate()
        return library
    }

    func style(id: String) -> HarmonicStyle? {
        styles.first { $0.id == id }
    }

    func validate() throws {
        var seenIDs: Set<String> = []

        for style in styles {
            let trimmedID = style.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedID.isEmpty else { throw StyleLibraryError.emptyStyleID }
            guard seenIDs.insert(trimmedID).inserted else { throw StyleLibraryError.duplicateStyleID(trimmedID) }
            guard !style.progressionSeeds.isEmpty else { throw StyleLibraryError.emptyProgressionSeeds(trimmedID) }
            guard !style.promptInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw StyleLibraryError.emptyPromptInstructions(trimmedID)
            }
        }
    }

    private static var defaultResourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }
}
