import SwiftUI

struct PianoRollKeyboardRow: Equatable, Identifiable {
    var pitch: Int
    var label: String
    var isBlackKey: Bool
    var normalizedY: Double
    var normalizedHeight: Double

    var id: Int { pitch }
}

struct PianoRollKeyboardLayout: Equatable {
    var pitchRange: ClosedRange<Int>

    var rows: [PianoRollKeyboardRow] {
        let pitches = Array(pitchRange).reversed()
        let count = max(pitchRange.upperBound - pitchRange.lowerBound + 1, 1)
        return pitches.enumerated().map { index, pitch in
            PianoRollKeyboardRow(
                pitch: pitch,
                label: Self.noteName(for: pitch),
                isBlackKey: Self.isBlackKey(pitch),
                normalizedY: Double(index) / Double(count),
                normalizedHeight: 1.0 / Double(count)
            )
        }
    }

    private static func isBlackKey(_ pitch: Int) -> Bool {
        [1, 3, 6, 8, 10].contains(((pitch % 12) + 12) % 12)
    }

    func pitch(atY yPosition: Double, height: Double) -> Int {
        let count = max(pitchRange.upperBound - pitchRange.lowerBound + 1, 1)
        guard height > 0 else { return pitchRange.upperBound }
        let rowHeight = height / Double(count)
        let clampedY = min(max(yPosition, 0), max(height - .ulpOfOne, 0))
        let rowIndex = min(max(Int(clampedY / rowHeight), 0), count - 1)
        return pitchRange.upperBound - rowIndex
    }

    private static func noteName(for pitch: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = pitch / 12 - 1
        return "\(names[((pitch % 12) + 12) % 12])\(octave)"
    }
}

struct PianoRollKeyboardStrip: View {
    var pitchRange: ClosedRange<Int>
    var onKeyDown: ((Int) -> Void)?
    var onKeyUp: ((Int) -> Void)?

    @State private var activePitch: Int?

    private var layout: PianoRollKeyboardLayout {
        PianoRollKeyboardLayout(pitchRange: pitchRange)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(layout.rows) { row in
                    Button {} label: {
                        HStack(spacing: 3) {
                            Text(row.label)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundStyle(row.isBlackKey ? StudioTheme.textPrimary : Color.black.opacity(0.82))
                        .background(keyFill(for: row))
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(StudioTheme.border)
                                .frame(height: 0.5)
                                .allowsHitTesting(false)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(row.label)
                    .accessibilityIdentifier("topliner.piano-roll.key.\(row.label)")
                }
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        handleTouch(at: value.location, in: proxy.size)
                    }
                    .onEnded { _ in
                        releaseActivePitch()
                    }
            )
        }
        .frame(width: StudioLayout.pianoKeyboardStripWidth)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .accessibilityLabel("Piano roll keyboard")
        .accessibilityIdentifier("topliner.piano-roll.keyboard")
    }

    private func handleTouch(at point: CGPoint, in size: CGSize) {
        let pitch = layout.pitch(atY: point.y, height: size.height)
        guard pitch != activePitch else { return }
        if let previousPitch = activePitch {
            onKeyUp?(previousPitch)
        }
        activePitch = pitch
        onKeyDown?(pitch)
    }

    private func releaseActivePitch() {
        guard let previousPitch = activePitch else { return }
        onKeyUp?(previousPitch)
        activePitch = nil
    }

    private func keyFill(for row: PianoRollKeyboardRow) -> some ShapeStyle {
        if row.isBlackKey {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.black.opacity(0.96), StudioTheme.elevatedSurface.opacity(0.98)],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
        return AnyShapeStyle(LinearGradient(
            colors: [Color.white.opacity(0.94), Color.white.opacity(0.72)],
            startPoint: .leading,
            endPoint: .trailing
        ))
    }
}

#Preview {
    PianoRollKeyboardStrip(pitchRange: 60...71)
        .frame(height: 360)
        .padding()
        .studioBackground()
}
