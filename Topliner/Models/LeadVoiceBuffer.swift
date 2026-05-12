import Foundation

struct LeadVoiceBuffer: Codable, Equatable {
    var notes: [MIDINoteEvent]
    var source: LeadVoiceSource
    var quantizeGrid: Double

    var sortedNotes: [MIDINoteEvent] {
        notes.sorted { lhs, rhs in
            if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
            return lhs.startBeat < rhs.startBeat
        }
    }
}

enum LeadVoiceSource: String, Codable, Equatable {
    case pianoRoll
    case microphone
    case importedMIDI
}
