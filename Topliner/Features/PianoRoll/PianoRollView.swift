import SwiftUI

struct PianoRollView: View {
    var notes: [MIDINoteEvent]
    var chordNotes: [MIDINoteEvent]
    var selectedNoteID: UUID?
    var totalBeats: Double = 16
    var beatsPerBar: Int = 4
    var pitchRange: ClosedRange<Int> = 48...84
    var viewport: PianoRollViewport?
    var quantizeGrid: Double = 0.25
    var currentBeat: Double?
    var pitchTrace: [PitchSample]
    var bpm: Double
    var onTap: ((CGPoint, PianoRollGeometry) -> Void)?
    var onDrag: ((CGPoint, PianoRollGeometry) -> Void)?
    var onResize: ((CGPoint, PianoRollGeometry) -> Void)?
    var onViewportChange: ((PianoRollViewport) -> Void)?

    init(
        notes: [MIDINoteEvent],
        chordNotes: [MIDINoteEvent] = [],
        selectedNoteID: UUID?,
        totalBeats: Double = 16,
        beatsPerBar: Int = 4,
        pitchRange: ClosedRange<Int> = 48...84,
        viewport: PianoRollViewport? = nil,
        quantizeGrid: Double = 0.25,
        currentBeat: Double? = nil,
        pitchTrace: [PitchSample] = [],
        bpm: Double = 120,
        onTap: ((CGPoint, PianoRollGeometry) -> Void)? = nil,
        onDrag: ((CGPoint, PianoRollGeometry) -> Void)? = nil,
        onResize: ((CGPoint, PianoRollGeometry) -> Void)? = nil,
        onViewportChange: ((PianoRollViewport) -> Void)? = nil
    ) {
        self.notes = notes
        self.chordNotes = chordNotes
        self.selectedNoteID = selectedNoteID
        self.totalBeats = totalBeats
        self.beatsPerBar = beatsPerBar
        self.pitchRange = pitchRange
        self.viewport = viewport
        self.quantizeGrid = quantizeGrid
        self.currentBeat = currentBeat
        self.pitchTrace = pitchTrace
        self.bpm = bpm
        self.onTap = onTap
        self.onDrag = onDrag
        self.onResize = onResize
        self.onViewportChange = onViewportChange
    }

    private var activeViewport: PianoRollViewport {
        if let viewport { return viewport }
        let count = pitchRange.upperBound - pitchRange.lowerBound + 1
        return PianoRollViewport(
            startBeat: 0,
            visibleBeats: totalBeats,
            centerPitch: pitchRange.lowerBound + max(count - 1, 0) / 2,
            visiblePitchCount: count,
            totalBeats: totalBeats,
            minVisibleBeats: min(4, totalBeats),
            maxVisibleBeats: totalBeats
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let viewport = activeViewport
            ZStack {
                PianoRollGridView(
                    startBeat: viewport.startBeat,
                    visibleBeats: viewport.visibleBeats,
                    beatsPerBar: beatsPerBar,
                    pitchRange: viewport.visiblePitchRange
                )

                if !pitchTrace.isEmpty {
                    PitchTraceView(
                        samples: pitchTrace,
                        bpm: bpm,
                        totalBeats: viewport.visibleBeats,
                        startBeat: viewport.startBeat,
                        pitchRange: viewport.visiblePitchRange,
                        quantizeGrid: quantizeGrid
                    )
                }

                PianoRollCanvasView(
                    notes: notes,
                    chordNotes: chordNotes,
                    selectedNoteID: selectedNoteID,
                    totalBeats: viewport.visibleBeats,
                    startBeat: viewport.startBeat,
                    pitchRange: viewport.visiblePitchRange,
                    quantizeGrid: quantizeGrid
                )

                if let currentBeat {
                    PlayheadView(currentBeat: currentBeat, startBeat: viewport.startBeat, visibleBeats: viewport.visibleBeats)
                }

                if let onTap {
                    PianoRollInteractionLayer(
                        notes: notes,
                        selectedNoteID: selectedNoteID,
                        totalBeats: viewport.visibleBeats,
                        startBeat: viewport.startBeat,
                        pitchRange: viewport.visiblePitchRange,
                        quantizeGrid: quantizeGrid,
                        onTap: onTap,
                        onDrag: onDrag,
                        onResize: onResize
                    )
                }

                if let onViewportChange {
                    PianoRollViewportGestureLayer { translation, size in
                        onViewportChange(viewport.pannedByPixels(translation, canvasSize: size))
                    } onZoom: { scale, anchor, size in
                        let anchorUnit = size.width > 0 ? anchor.x / size.width : 0.5
                        onViewportChange(viewport.zoomedTime(by: scale, anchorUnit: Double(anchorUnit)))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityValue("Visible beats \(viewport.startBeat) to \(viewport.endBeat), pitches \(viewport.visiblePitchRange.lowerBound) to \(viewport.visiblePitchRange.upperBound)")
        }
    }
}

#Preview {
    PianoRollView(
        notes: [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 67, startBeat: 2, durationBeats: 2, velocity: 100),
            MIDINoteEvent(pitch: 72, startBeat: 5, durationBeats: 1.5, velocity: 100)
        ],
        selectedNoteID: nil,
        viewport: .default(totalBeats: 16)
    )
    .frame(height: 360)
    .padding()
    .background(Color.black)
}
