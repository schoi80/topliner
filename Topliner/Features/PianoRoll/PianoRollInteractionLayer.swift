import SwiftUI

struct PianoRollInteractionLayer: View {
    var notes: [MIDINoteEvent] = []
    var selectedNoteID: UUID?
    var totalBeats: Double = 16
    var startBeat: Double = 0
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25
    var onTap: (CGPoint, PianoRollGeometry) -> Void
    var onDrag: ((CGPoint, PianoRollGeometry) -> Void)? = nil
    var onResize: ((CGPoint, PianoRollGeometry) -> Void)? = nil
    var onNoteTouchDown: ((MIDINoteEvent) -> Void)? = nil

    @State private var didBeginTouch = false
    @State private var didDrag = false
    @State private var activeDragMode: DragMode?

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.black.opacity(0.001))
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Piano roll interaction layer")
                .accessibilityIdentifier("topliner.piano-roll.viewport")
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let geometry = geometry(for: proxy.size)
                            if !didBeginTouch {
                                didBeginTouch = true
                                if let touchedNote = note(at: value.startLocation, geometry: geometry) {
                                    onNoteTouchDown?(touchedNote)
                                }
                            }
                            guard isDrag(value) else { return }
                            didDrag = true
                            let dragMode = activeDragMode ?? dragMode(for: value.startLocation, geometry: geometry)
                            activeDragMode = dragMode
                            handleDrag(value.location, geometry: geometry, mode: dragMode)
                        }
                        .onEnded { value in
                            let geometry = geometry(for: proxy.size)
                            if isDrag(value) {
                                let dragMode = activeDragMode ?? dragMode(for: value.startLocation, geometry: geometry)
                                handleDrag(value.location, geometry: geometry, mode: dragMode)
                            } else if !didDrag {
                                onTap(value.location, geometry)
                            }
                            didBeginTouch = false
                            didDrag = false
                            activeDragMode = nil
                        }
                )
        }
    }

    private func geometry(for size: CGSize) -> PianoRollGeometry {
        PianoRollGeometry(
            size: size,
            pitchRange: pitchRange,
            startBeat: startBeat,
            visibleBeats: totalBeats,
            quantizeGrid: quantizeGrid
        )
    }

    private func isDrag(_ value: DragGesture.Value) -> Bool {
        abs(value.translation.width) > 2 || abs(value.translation.height) > 2
    }

    private func note(at point: CGPoint, geometry: PianoRollGeometry) -> MIDINoteEvent? {
        notes.first { note in
            geometry.rect(for: note).contains(point)
        }
    }

    private func dragMode(for point: CGPoint, geometry: PianoRollGeometry) -> DragMode {
        if let selectedNoteID,
           let selectedNote = notes.first(where: { $0.id == selectedNoteID }) {
            let drawableNote = PianoRollDrawableNote(
                note: selectedNote,
                rect: geometry.rect(for: selectedNote),
                isSelected: true
            )
            if drawableNote.resizeHandleHitRect?.contains(point) == true {
                return .resize
            }
        }
        return .move
    }

    private func handleDrag(_ point: CGPoint, geometry: PianoRollGeometry, mode: DragMode) {
        switch mode {
        case .move:
            onDrag?(point, geometry)
        case .resize:
            onResize?(point, geometry)
        }
    }

    private enum DragMode {
        case move
        case resize
    }
}

#Preview {
    PianoRollInteractionLayer { _, _ in }
        .frame(height: 360)
        .background(Color.black.opacity(0.8))
}
