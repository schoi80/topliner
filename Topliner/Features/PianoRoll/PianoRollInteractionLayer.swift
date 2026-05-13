import SwiftUI

struct PianoRollInteractionLayer: View {
    var totalBeats: Double = 16
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25
    var onTap: (CGPoint, PianoRollGeometry) -> Void
    var onDrag: ((CGPoint, PianoRollGeometry) -> Void)? = nil

    @State private var didDrag = false

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isDrag(value), let onDrag else { return }
                            didDrag = true
                            onDrag(value.location, geometry(for: proxy.size))
                        }
                        .onEnded { value in
                            let geometry = geometry(for: proxy.size)
                            if isDrag(value), let onDrag {
                                onDrag(value.location, geometry)
                            } else if !didDrag {
                                onTap(value.location, geometry)
                            }
                            didDrag = false
                        }
                )
        }
        .accessibilityLabel("Piano roll interaction layer")
    }

    private func geometry(for size: CGSize) -> PianoRollGeometry {
        PianoRollGeometry(
            size: size,
            pitchRange: pitchRange,
            totalBeats: totalBeats,
            quantizeGrid: quantizeGrid
        )
    }

    private func isDrag(_ value: DragGesture.Value) -> Bool {
        abs(value.translation.width) > 2 || abs(value.translation.height) > 2
    }
}

#Preview {
    PianoRollInteractionLayer { _, _ in }
        .frame(height: 360)
        .background(Color.black.opacity(0.8))
}
