import SwiftUI

struct PianoRollVerticalGridLine: Equatable {
    var beat: Double
    var normalizedX: Double
    var isMajor: Bool
}

struct PianoRollHorizontalGridLine: Equatable {
    var pitch: Int
    var normalizedY: Double
}

struct PianoRollGridMetrics {
    var totalBeats: Double
    var beatsPerBar: Int
    var pitchRange: ClosedRange<Int>

    func verticalLines() -> [PianoRollVerticalGridLine] {
        guard totalBeats > 0 else { return [] }

        let lastBeat = Int(totalBeats.rounded(.down))
        return (0...lastBeat).map { beatIndex in
            let beat = Double(beatIndex)
            return PianoRollVerticalGridLine(
                beat: beat,
                normalizedX: beat / totalBeats,
                isMajor: isBarBoundary(beatIndex)
            )
        }
    }

    func horizontalLines() -> [PianoRollHorizontalGridLine] {
        let pitchCount = pitchRange.upperBound - pitchRange.lowerBound + 1
        guard pitchCount > 0 else { return [] }

        return (0...pitchCount).map { laneBoundary in
            PianoRollHorizontalGridLine(
                pitch: pitchRange.lowerBound + laneBoundary,
                normalizedY: Double(laneBoundary) / Double(pitchCount)
            )
        }
    }

    private func isBarBoundary(_ beatIndex: Int) -> Bool {
        guard beatsPerBar > 0 else { return false }
        return beatIndex.isMultiple(of: beatsPerBar)
    }
}

struct PianoRollGridView: View {
    var totalBeats: Double = 16
    var beatsPerBar: Int = 4
    var pitchRange: ClosedRange<Int> = 48...84

    private var metrics: PianoRollGridMetrics {
        PianoRollGridMetrics(totalBeats: totalBeats, beatsPerBar: beatsPerBar, pitchRange: pitchRange)
    }

    var body: some View {
        Canvas { context, size in
            drawBackground(in: &context, size: size)
            drawHorizontalLines(in: &context, size: size)
            drawVerticalLines(in: &context, size: size)
        }
        .background(Color(red: 0.04, green: 0.045, blue: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("Four bar piano roll grid")
    }

    private func drawBackground(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(rect), with: .color(Color(red: 0.04, green: 0.045, blue: 0.06)))
    }

    private func drawVerticalLines(in context: inout GraphicsContext, size: CGSize) {
        for line in metrics.verticalLines() {
            let x = size.width * line.normalizedX
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))

            context.stroke(
                path,
                with: .color(Color.white.opacity(line.isMajor ? 0.28 : 0.12)),
                lineWidth: line.isMajor ? 1.5 : 0.75
            )
        }
    }

    private func drawHorizontalLines(in context: inout GraphicsContext, size: CGSize) {
        for line in metrics.horizontalLines() {
            let y = size.height * line.normalizedY
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))

            context.stroke(
                path,
                with: .color(Color.white.opacity(isOctaveBoundary(line.pitch) ? 0.16 : 0.07)),
                lineWidth: isOctaveBoundary(line.pitch) ? 1 : 0.5
            )
        }
    }

    private func isOctaveBoundary(_ pitch: Int) -> Bool {
        pitch.isMultiple(of: 12)
    }
}

#Preview {
    PianoRollGridView()
        .frame(height: 360)
        .padding()
        .background(Color.black)
}
