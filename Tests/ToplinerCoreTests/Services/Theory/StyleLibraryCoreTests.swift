import XCTest
@testable import ToplinerCore

final class StyleLibraryCoreTests: XCTestCase {
    func testDefaultLibraryLoadsAllInitialHarmonicStyles() throws {
        let library = try StyleLibrary.defaultLibrary()

        XCTAssertEqual(
            library.styles.map(\.id),
            [
                "neo_soul",
                "jazz",
                "gospel_rnb",
                "city_pop",
                "bossa_nova",
                "blues",
                "funk",
                "synthwave",
                "cinematic"
            ]
        )
    }

    func testEveryDefaultStyleHasAtLeastOneProgressionSeed() throws {
        let library = try StyleLibrary.defaultLibrary()

        for style in library.styles {
            XCTAssertFalse(style.progressionSeeds.isEmpty, "\(style.id) should include at least one progression seed")
            for seed in style.progressionSeeds {
                XCTAssertFalse(seed.name.isEmpty, "\(style.id) seed should have a name")
                XCTAssertFalse(seed.chords.isEmpty, "\(style.id) seed \(seed.name) should include chords")
            }
        }
    }

    func testEveryDefaultStyleHasPromptInstructions() throws {
        let library = try StyleLibrary.defaultLibrary()

        for style in library.styles {
            XCTAssertFalse(style.promptInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    func testFindStyleByIdentifier() throws {
        let library = try StyleLibrary.defaultLibrary()

        let style = library.style(id: "neo_soul")

        XCTAssertEqual(style?.displayName, "Neo-soul")
        XCTAssertTrue(style?.promptInstructions.localizedCaseInsensitiveContains("extended chords") == true)
    }

    func testDecodeRejectsDuplicateStyleIdentifiers() throws {
        let json = """
        {
          "styles": [
            {
              "id": "neo_soul",
              "displayName": "Neo-soul",
              "promptInstructions": "Use rich harmony.",
              "progressionSeeds": [
                { "name": "seed", "chords": ["Imaj7", "vi9"] }
              ]
            },
            {
              "id": "neo_soul",
              "displayName": "Neo-soul duplicate",
              "promptInstructions": "Duplicate style.",
              "progressionSeeds": [
                { "name": "seed", "chords": ["ii7", "V7"] }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try StyleLibrary.decode(json)) { error in
            XCTAssertEqual(error as? StyleLibraryError, .duplicateStyleID("neo_soul"))
        }
    }
}
