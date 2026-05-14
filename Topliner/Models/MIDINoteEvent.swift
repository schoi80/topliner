import Foundation

struct MIDINoteEvent: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var pitch: Int
    var startBeat: Double
    var durationBeats: Double
    var velocity: Int

    var endBeat: Double { startBeat + durationBeats }
}
