import Foundation

struct ChordEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var symbol: String
    var rootMidiNote: Int
    var midiNotes: [Int]
    var startBeat: Double
    var durationBeats: Double
    var romanNumeral: String?
    var confidence: Double?
}

struct ChordProgression: Codable, Equatable {
    var styleID: String
    var key: String?
    var chords: [ChordEvent]
    var explanation: String?
}
