import SwiftUI

struct PitchTraceDrawableBlock: Equatable {
    var pitch: Int
    var rect: CGRect
    var opacity: Double
}

struct PitchTraceLayout {
    var samples: [PitchSample]
    var bpm: Double
    var sampleDurationSeconds: Double = 0.1
    var geometry: PianoRollGeometry

    func drawableBlocks() -> [PitchTraceDrawableBlock] {
        guard bpm > 0, sampleDurationSeconds > 0 else { return [] }

        return samples
            .filter { geometry.pitchRange.contains($0.midiNote) }
            .sorted { lhs, rhs in
                if lhs.timestamp == rhs.timestamp { return lhs.midiNote < rhs.midiNote }
                return lhs.timestamp < rhs.timestamp
            }
            .map { sample in
                let startBeat = secondsToBeats(sample.timestamp)
                let durationBeats = secondsToBeats(sampleDurationSeconds)
                let note = MIDINoteEvent(
                    pitch: sample.midiNote,
                    startBeat: startBeat,
                    durationBeats: durationBeats,
                    velocity: 1
                )

                return PitchTraceDrawableBlock(
                    pitch: sample.midiNote,
                    rect: geometry.rect(for: note),
                    opacity: opacity(forAmplitude: sample.amplitude)
                )
            }
    }

    private func secondsToBeats(_ seconds: Double) -> Double {
        seconds * bpm / 60.0
    }

    private func opacity(forAmplitude amplitude: Double) -> Double {
        guard amplitude > 0.1 else { return 0.18 }
        let clampedAmplitude = min(max(amplitude, 0), 1)
        return 0.18 + (0.34 * clampedAmplitude)
    }
}

struct PitchTraceView: View {
    var samples: [PitchSample]
    var bpm: Double
    var sampleDurationSeconds: Double = 0.1
    var totalBeats: Double = 16
    var pitchRange: ClosedRange<Int> = 48...84
    var quantizeGrid: Double = 0.25

    var body: some View {
        Canvas { context, size in
            let geometry = PianoRollGeometry(
                size: size,
                pitchRange: pitchRange,
                totalBeats: totalBeats,
                quantizeGrid: quantizeGrid
            )
            let layout = PitchTraceLayout(
                samples: samples,
                bpm: bpm,
                sampleDurationSeconds: sampleDurationSeconds,
                geometry: geometry
            )

            for block in layout.drawableBlocks() {
                let path = Path(roundedRect: block.rect.insetBy(dx: 0.5, dy: 4), cornerRadius: 4)
                context.fill(
                    path,
                    with: .color(Color.cyan.opacity(block.opacity))
                )
            }
        }
        .accessibilityLabel("Ghost pitch trace")
    }
}

#Preview {
    PitchTraceView(
        samples: [
            PitchSample(timestamp: 0.0, frequency: 261.63, midiNote: 60, amplitude: 0.4),
            PitchSample(timestamp: 0.2, frequency: 293.66, midiNote: 62, amplitude: 0.5),
            PitchSample(timestamp: 0.4, frequency: 329.63, midiNote: 64, amplitude: 0.8)
        ],
        bpm: 120
    )
    .frame(height: 220)
    .background(.black)
}
