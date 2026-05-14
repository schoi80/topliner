import CoreGraphics
import SwiftUI

struct PlayheadLayout: Equatable {
    var currentBeat: Double
    var startBeat: Double
    var visibleBeats: Double
    var width: CGFloat

    init(currentBeat: Double, totalBeats: Double, width: CGFloat) {
        self.init(currentBeat: currentBeat, startBeat: 0, visibleBeats: totalBeats, width: width)
    }

    init(currentBeat: Double, startBeat: Double, visibleBeats: Double, width: CGFloat) {
        self.currentBeat = currentBeat
        self.startBeat = startBeat
        self.visibleBeats = visibleBeats
        self.width = width
    }

    var xPosition: CGFloat {
        guard visibleBeats > 0, width > 0 else { return 0 }
        let clampedBeat = min(max(currentBeat, startBeat), startBeat + visibleBeats)
        return CGFloat((clampedBeat - startBeat) / visibleBeats) * width
    }
}

struct PlayheadView: View {
    var currentBeat: Double
    var startBeat: Double = 0
    var visibleBeats: Double = 16

    init(currentBeat: Double, totalBeats: Double = 16) {
        self.currentBeat = currentBeat
        self.startBeat = 0
        self.visibleBeats = totalBeats
    }

    init(currentBeat: Double, startBeat: Double, visibleBeats: Double) {
        self.currentBeat = currentBeat
        self.startBeat = startBeat
        self.visibleBeats = visibleBeats
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = PlayheadLayout(currentBeat: currentBeat, startBeat: startBeat, visibleBeats: visibleBeats, width: proxy.size.width)

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
