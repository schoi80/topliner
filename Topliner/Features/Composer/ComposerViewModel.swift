import CoreGraphics
import Foundation
import Observation

@Observable
final class ComposerViewModel {
    var leadVoice: LeadVoiceBuffer
    var selectedNoteID: UUID?

    init(leadVoice: LeadVoiceBuffer = LeadVoiceBuffer(notes: [], source: .pianoRoll, quantizeGrid: 0.25), selectedNoteID: UUID? = nil) {
        self.leadVoice = leadVoice
        self.selectedNoteID = selectedNoteID
    }

    func handlePianoRollTap(at point: CGPoint, geometry: PianoRollGeometry) {
        if let tappedNote = note(at: point, geometry: geometry) {
            selectedNoteID = tappedNote.id
            return
        }

        let noteStart = geometry.noteStart(at: point)
        let note = MIDINoteEvent(
            pitch: noteStart.pitch,
            startBeat: noteStart.beat,
            durationBeats: 1,
            velocity: 100
        )
        leadVoice.notes.append(note)
        selectedNoteID = note.id
    }

    func handlePianoRollDrag(to point: CGPoint, geometry: PianoRollGeometry) {
        guard let selectedNoteID,
              let noteIndex = leadVoice.notes.firstIndex(where: { $0.id == selectedNoteID })
        else { return }

        let noteStart = geometry.noteStart(at: point)
        leadVoice.notes[noteIndex].pitch = noteStart.pitch
        leadVoice.notes[noteIndex].startBeat = max(0, noteStart.beat)
    }

    func handlePianoRollResize(to point: CGPoint, geometry: PianoRollGeometry) {
        guard let selectedNoteID,
              let noteIndex = leadVoice.notes.firstIndex(where: { $0.id == selectedNoteID })
        else { return }

        let note = leadVoice.notes[noteIndex]
        let endBeat = Quantizer.quantizeBeat(geometry.beat(atX: point.x), grid: geometry.quantizeGrid)
        let minimumDuration = geometry.quantizeGrid
        leadVoice.notes[noteIndex].durationBeats = max(minimumDuration, endBeat - note.startBeat)
    }

    func deleteSelectedNote() {
        guard let selectedNoteID else { return }
        leadVoice.notes.removeAll { $0.id == selectedNoteID }
        self.selectedNoteID = nil
    }

    func clearLeadNotes() {
        leadVoice.notes.removeAll()
        selectedNoteID = nil
    }

    private func note(at point: CGPoint, geometry: PianoRollGeometry) -> MIDINoteEvent? {
        leadVoice.notes.first { note in
            geometry.rect(for: note).contains(point)
        }
    }
}
