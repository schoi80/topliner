import Foundation

struct ChordGenerationRequest: Equatable {
    var styleID: String
    var key: String
    var bpm: Double
    var melodyNotes: [MIDINoteEvent]
    var totalBeats: Double
    var complexity: ChordGenerationComplexity = .balanced
    var previousProgression: ChordProgression?
    var variantIndex: Int = 0
}

enum ChordGenerationError: Error, Equatable {
    case unknownStyle(String)
    case emptyProgressionSeed(String)
    case invalidTotalBeats(Double)
}

protocol ChordGenerationProviding {
    func generateProgression(for request: ChordGenerationRequest) throws -> ChordProgression
}
