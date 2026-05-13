import SwiftUI

struct PianoRollInteractionLayer: View {
    var totalBeats: Double = 16
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25
    var onTap: (CGPoint, PianoRollGeometry) -> Void

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let geometry = PianoRollGeometry(
                                size: proxy.size,
                                pitchRange: pitchRange,
                                totalBeats: totalBeats,
                                quantizeGrid: quantizeGrid
                            )
                            onTap(value.location, geometry)
                        }
                )
        }
        .accessibilityLabel("Piano roll interaction layer")
    }
}

#Preview {
    PianoRollInteractionLayer { _, _ in }
        .frame(height: 360)
        .background(Color.black.opacity(0.8))
}
