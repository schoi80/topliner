import CoreGraphics
import Foundation
import Observation

@Observable
final class ComposerViewModel {
    var leadVoice: LeadVoiceBuffer
    var selectedNoteID: UUID?
    var isMetronomeEnabled: Bool
    private var storedBPM: Double
    private var storedBarLength: Int

    var bpm: Double {
        get { storedBPM }
        set { storedBPM = min(max(newValue, 40), 240) }
    }

    var barLength: Int {
        get { storedBarLength }
        set { storedBarLength = min(max(newValue, 1), 16) }
    }

    var totalBeats: Double { Double(barLength * 4) }

    var selectedNote: MIDINoteEvent? {
        guard let selectedNoteID else { return nil }
        return leadVoice.notes.first { $0.id == selectedNoteID }
    }

    init(
        leadVoice: LeadVoiceBuffer = LeadVoiceBuffer(notes: [], source: .pianoRoll, quantizeGrid: 0.25),
        selectedNoteID: UUID? = nil,
        bpm: Double = 120,
        barLength: Int = 4,
        isMetronomeEnabled: Bool = false
    ) {
        self.leadVoice = leadVoice
        self.selectedNoteID = selectedNoteID
        storedBPM = min(max(bpm, 40), 240)
        storedBarLength = min(max(barLength, 1), 16)
        self.isMetronomeEnabled = isMetronomeEnabled
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

    func updateSelectedNote(pitch: Int, startBeat: Double, durationBeats: Double, velocity: Int) {
        guard let selectedNoteID,
              let noteIndex = leadVoice.notes.firstIndex(where: { $0.id == selectedNoteID })
        else { return }

        let grid = leadVoice.quantizeGrid
        leadVoice.notes[noteIndex].pitch = min(max(pitch, 0), 127)
        leadVoice.notes[noteIndex].startBeat = max(0, Quantizer.quantizeBeat(startBeat, grid: grid))
        leadVoice.notes[noteIndex].durationBeats = max(grid, Quantizer.quantizeBeat(durationBeats, grid: grid))
        leadVoice.notes[noteIndex].velocity = min(max(velocity, 0), 127)
    }

    func duplicateSelectedNote() {
        guard let selectedNote else { return }
        var copiedNote = selectedNote
        copiedNote.id = UUID()
        copiedNote.startBeat = Quantizer.quantizeBeat(selectedNote.startBeat + selectedNote.durationBeats, grid: leadVoice.quantizeGrid)
        leadVoice.notes.append(copiedNote)
        selectedNoteID = copiedNote.id
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
