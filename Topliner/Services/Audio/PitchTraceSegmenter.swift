import Foundation

protocol PitchTraceSegmenting: AnyObject {
    func segment(trace: [PitchSample], bpm: Double) -> [MIDINoteEvent]
}

final class PitchTraceSegmenter: PitchTraceSegmenting {
    let amplitudeThreshold: Double
    let maximumMergeGapSeconds: Double
    let sampleDurationSeconds: Double
    let quantizeGridBeats: Double
    let minimumDurationBeats: Double
    let defaultVelocity: Int

    init(
        amplitudeThreshold: Double = 0.1,
        maximumMergeGapSeconds: Double = 0.12,
        sampleDurationSeconds: Double = 0.1,
        quantizeGridBeats: Double = 0.25,
        minimumDurationBeats: Double = 0.25,
        defaultVelocity: Int = 96
    ) {
        self.amplitudeThreshold = amplitudeThreshold
        self.maximumMergeGapSeconds = maximumMergeGapSeconds
        self.sampleDurationSeconds = sampleDurationSeconds
        self.quantizeGridBeats = quantizeGridBeats
        self.minimumDurationBeats = minimumDurationBeats
        self.defaultVelocity = defaultVelocity
    }

    func segment(trace: [PitchSample], bpm: Double) -> [MIDINoteEvent] {
        guard bpm > 0, sampleDurationSeconds > 0 else { return [] }

        let sortedTrace = trace.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp { return lhs.midiNote < rhs.midiNote }
            return lhs.timestamp < rhs.timestamp
        }

        var finalizedNotes: [MIDINoteEvent] = []
        var activeSegment: PitchSegment?

        for sample in sortedTrace {
            guard sample.amplitude >= amplitudeThreshold else {
                finalize(activeSegment, bpm: bpm, into: &finalizedNotes)
                activeSegment = nil
                continue
            }

            if let segment = activeSegment,
               segment.pitch == sample.midiNote,
               sample.timestamp - segment.lastTimestamp <= maximumMergeGapSeconds {
                activeSegment = segment.extending(to: sample.timestamp)
            } else {
                finalize(activeSegment, bpm: bpm, into: &finalizedNotes)
                activeSegment = PitchSegment(
                    pitch: sample.midiNote,
                    firstTimestamp: sample.timestamp,
                    lastTimestamp: sample.timestamp
                )
            }
        }

        finalize(activeSegment, bpm: bpm, into: &finalizedNotes)
        return finalizedNotes.sorted { lhs, rhs in
            if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
            return lhs.startBeat < rhs.startBeat
        }
    }

    private func finalize(_ segment: PitchSegment?, bpm: Double, into notes: inout [MIDINoteEvent]) {
        guard let segment else { return }

        let rawStartBeat = secondsToBeats(segment.firstTimestamp, bpm: bpm)
        let rawDurationBeats = secondsToBeats(
            segment.lastTimestamp - segment.firstTimestamp + sampleDurationSeconds,
            bpm: bpm
        )

        let startBeat = Quantizer.quantizeBeat(rawStartBeat, grid: quantizeGridBeats)
        let durationBeats = max(
            minimumDurationBeats,
            Quantizer.quantizeBeat(rawDurationBeats, grid: quantizeGridBeats)
        )

        guard Quantizer.quantizeBeat(rawDurationBeats, grid: quantizeGridBeats) > 0 else { return }

        notes.append(
            MIDINoteEvent(
                pitch: segment.pitch,
                startBeat: startBeat,
                durationBeats: durationBeats,
                velocity: defaultVelocity
            )
        )
    }

    private func secondsToBeats(_ seconds: Double, bpm: Double) -> Double {
        seconds * bpm / 60.0
    }
}

private struct PitchSegment {
    var pitch: Int
    var firstTimestamp: Double
    var lastTimestamp: Double

    func extending(to timestamp: Double) -> PitchSegment {
        PitchSegment(
            pitch: pitch,
            firstTimestamp: firstTimestamp,
            lastTimestamp: timestamp
        )
    }
}
