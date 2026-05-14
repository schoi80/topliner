import CoreGraphics

struct PianoRollGeometry {
    var size: CGSize
    var pitchRange: ClosedRange<Int>
    var startBeat: Double
    var visibleBeats: Double
    var quantizeGrid: Double

    init(size: CGSize, pitchRange: ClosedRange<Int>, totalBeats: Double, quantizeGrid: Double) {
        self.init(
            size: size,
            pitchRange: pitchRange,
            startBeat: 0,
            visibleBeats: totalBeats,
            quantizeGrid: quantizeGrid
        )
    }

    init(size: CGSize, pitchRange: ClosedRange<Int>, startBeat: Double, visibleBeats: Double, quantizeGrid: Double) {
        self.size = size
        self.pitchRange = pitchRange
        self.startBeat = startBeat
        self.visibleBeats = visibleBeats
        self.quantizeGrid = quantizeGrid
    }

    func rect(for note: MIDINoteEvent) -> CGRect {
        let x = xPosition(forBeat: note.startBeat)
        let y = yPosition(forPitch: note.pitch)
        let width = beatWidth * note.durationBeats

        return CGRect(x: x, y: y, width: width, height: laneHeight)
    }

    func beat(atX x: CGFloat) -> Double {
        guard size.width > 0, visibleBeats > 0 else { return startBeat }
        let clampedX = min(max(x, 0), size.width)
        return startBeat + Double(clampedX / size.width) * visibleBeats
    }

    func pitch(atY y: CGFloat) -> Int {
        let count = pitchCount
        guard count > 0, size.height > 0 else { return pitchRange.lowerBound }

        let clampedY = min(max(y, 0), max(size.height - 0.0001, 0))
        let row = min(Int(clampedY / laneHeight), count - 1)
        return pitchRange.upperBound - row
    }

    func noteStart(at point: CGPoint) -> (pitch: Int, beat: Double) {
        (
            pitch: pitch(atY: point.y),
            beat: Quantizer.quantizeBeat(beat(atX: point.x), grid: quantizeGrid)
        )
    }

    private var pitchCount: Int {
        pitchRange.upperBound - pitchRange.lowerBound + 1
    }

    private var beatWidth: CGFloat {
        guard visibleBeats > 0 else { return 0 }
        return size.width / CGFloat(visibleBeats)
    }

    private var laneHeight: CGFloat {
        guard pitchCount > 0 else { return 0 }
        return size.height / CGFloat(pitchCount)
    }

    private func xPosition(forBeat beat: Double) -> CGFloat {
        CGFloat(beat - startBeat) * beatWidth
    }

    private func yPosition(forPitch pitch: Int) -> CGFloat {
        let clampedPitch = min(max(pitch, pitchRange.lowerBound), pitchRange.upperBound)
        let row = pitchRange.upperBound - clampedPitch
        return CGFloat(row) * laneHeight
    }
}
