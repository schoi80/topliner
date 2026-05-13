import Foundation

struct ChordGenerationRequest: Equatable {
    var styleID: String
    var key: String
    var bpm: Double
    var melodyNotes: [MIDINoteEvent]
    var totalBeats: Double
    var complexity: ChordGenerationComplexity = .balanced
}

enum ChordGenerationError: Error, Equatable {
    case unknownStyle(String)
    case emptyProgressionSeed(String)
    case invalidTotalBeats(Double)
}

protocol ChordGenerationProviding {
    func generateProgression(for request: ChordGenerationRequest) throws -> ChordProgression
}
