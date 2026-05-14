import CoreGraphics
import Foundation

struct PianoRollViewport: Equatable {
    var startBeat: Double
    var visibleBeats: Double
    var centerPitch: Int
    var visiblePitchCount: Int
    var totalBeats: Double
    var minVisibleBeats: Double
    var maxVisibleBeats: Double

    init(
        startBeat: Double,
        visibleBeats: Double,
        centerPitch: Int,
        visiblePitchCount: Int,
        totalBeats: Double,
        minVisibleBeats: Double = 4,
        maxVisibleBeats: Double? = nil
    ) {
        let resolvedMaxVisibleBeats = max(maxVisibleBeats ?? totalBeats, minVisibleBeats)
        self.totalBeats = max(totalBeats, minVisibleBeats)
        self.minVisibleBeats = minVisibleBeats
        self.maxVisibleBeats = min(resolvedMaxVisibleBeats, self.totalBeats)
        self.visiblePitchCount = min(max(visiblePitchCount, 1), 128)
        self.centerPitch = centerPitch
        self.visibleBeats = visibleBeats
        self.startBeat = startBeat
        clampInPlace()
    }

    static func `default`(totalBeats: Double) -> PianoRollViewport {
        PianoRollViewport(
            startBeat: 0,
            visibleBeats: totalBeats,
            centerPitch: 65,
            visiblePitchCount: 12,
            totalBeats: totalBeats,
            minVisibleBeats: 4,
            maxVisibleBeats: totalBeats
        )
    }

    var endBeat: Double {
        startBeat + visibleBeats
    }

    var visiblePitchRange: ClosedRange<Int> {
        let halfSpan = (visiblePitchCount - 1) / 2
        let lower = min(max(centerPitch - halfSpan, 0), 127 - visiblePitchCount + 1)
        return lower...(lower + visiblePitchCount - 1)
    }

    func panned(beatsDelta: Double, pitchDelta: Int) -> PianoRollViewport {
        var next = self
        next.startBeat += beatsDelta
        next.centerPitch += pitchDelta
        next.clampInPlace()
        return next
    }

    func pannedByPixels(_ translation: CGSize, canvasSize: CGSize) -> PianoRollViewport {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return self }
        let beatsDelta = -Double(translation.width / canvasSize.width) * visibleBeats
        let pitchDelta = Int((-translation.height / laneHeight(for: canvasSize)).rounded())
        return panned(beatsDelta: beatsDelta, pitchDelta: pitchDelta)
    }

    func zoomedTime(by scale: Double, anchorUnit: Double) -> PianoRollViewport {
        guard scale.isFinite, scale > 0 else { return self }
        let anchor = min(max(anchorUnit, 0), 1)
        let anchoredBeat = startBeat + visibleBeats * anchor
        var next = self
        next.visibleBeats = visibleBeats / scale
        next.clampVisibleBeats()
        next.startBeat = anchoredBeat - next.visibleBeats * anchor
        next.clampInPlace()
        return next
    }

    private func laneHeight(for canvasSize: CGSize) -> CGFloat {
        canvasSize.height / CGFloat(max(visiblePitchCount, 1))
    }

    private mutating func clampInPlace() {
        clampVisibleBeats()
        centerPitch = min(max(centerPitch, visiblePitchRange.lowerBound + ((visiblePitchCount - 1) / 2)), visiblePitchRange.upperBound - (visiblePitchCount / 2))
        let currentRange = visiblePitchRange
        if currentRange.lowerBound == 0 {
            centerPitch = (visiblePitchCount - 1) / 2
        } else if currentRange.upperBound == 127 {
            centerPitch = 127 - (visiblePitchCount / 2)
        }
        startBeat = min(max(startBeat, 0), max(totalBeats - visibleBeats, 0))
    }

    private mutating func clampVisibleBeats() {
        visibleBeats = min(max(visibleBeats, minVisibleBeats), min(maxVisibleBeats, totalBeats))
    }
}
