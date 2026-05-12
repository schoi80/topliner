import Foundation

struct ProjectDocument: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var bpm: Double
    var beatsPerBar: Int
    var totalBars: Int
    var key: String?
    var scale: String?
    var leadVoice: LeadVoiceBuffer
    var chordProgression: ChordProgression?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        bpm: Double = 120,
        beatsPerBar: Int = 4,
        totalBars: Int = 4,
        key: String? = nil,
        scale: String? = nil,
        leadVoice: LeadVoiceBuffer = LeadVoiceBuffer(notes: [], source: .pianoRoll, quantizeGrid: 0.25),
        chordProgression: ChordProgression? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.totalBars = totalBars
        self.key = key
        self.scale = scale
        self.leadVoice = leadVoice
        self.chordProgression = chordProgression
    }
}
