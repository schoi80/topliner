import CoreGraphics
import SwiftUI

struct PlayheadLayout: Equatable {
    var currentBeat: Double
    var totalBeats: Double
    var width: CGFloat

    var xPosition: CGFloat {
        guard totalBeats > 0, width > 0 else { return 0 }
        let clampedBeat = min(max(currentBeat, 0), totalBeats)
        return CGFloat(clampedBeat / totalBeats) * width
    }
}

struct PlayheadView: View {
    var currentBeat: Double
    var totalBeats: Double = 16

    var body: some View {
        GeometryReader { proxy in
            let layout = PlayheadLayout(currentBeat: currentBeat, totalBeats: totalBeats, width: proxy.size.width)

            Rectangle()
                .fill(Color(red: 1.0, green: 0.32, blue: 0.42).opacity(0.92))
                .frame(width: 2)
                .shadow(color: Color(red: 1.0, green: 0.32, blue: 0.42).opacity(0.55), radius: 6)
                .position(x: layout.xPosition, y: proxy.size.height / 2)
                .accessibilityLabel("Piano roll playhead")
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    PlayheadView(currentBeat: 4, totalBeats: 16)
        .frame(height: 320)
        .padding()
        .background(Color.black)
}
