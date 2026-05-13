import Foundation

struct PitchObservation: Equatable {
    var timestamp: Double
    var frequency: Double
    var amplitude: Double
}

struct PitchSample: Equatable, Identifiable {
    var id: String { "\(timestamp)-\(midiNote)" }
    var timestamp: Double
    var frequency: Double
    var midiNote: Int
    var amplitude: Double
}

protocol PitchTrackingManaging: AnyObject {
    func track(buffer: CapturedAudioBuffer) -> [PitchSample]
}

final class PitchTrackingService: PitchTrackingManaging {
    let amplitudeThreshold: Double
    let analysisWindowSize: Int
    let analysisHopSize: Int

    init(
        amplitudeThreshold: Double = 0.05,
        analysisWindowSize: Int = 2_048,
        analysisHopSize: Int = 1_024
    ) {
        self.amplitudeThreshold = amplitudeThreshold
        self.analysisWindowSize = analysisWindowSize
        self.analysisHopSize = analysisHopSize
    }

    static func midiNoteNumber(frequency: Double) -> Int {
        Int((12.0 * log2(frequency / 440.0) + 69.0).rounded())
    }

    func track(observations: [PitchObservation]) -> [PitchSample] {
        observations.compactMap { observation in
            guard observation.frequency > 0, observation.amplitude >= amplitudeThreshold else {
                return nil
            }

            return PitchSample(
                timestamp: observation.timestamp,
                frequency: observation.frequency,
                midiNote: Self.midiNoteNumber(frequency: observation.frequency),
                amplitude: observation.amplitude
            )
        }
    }

    func track(buffer: CapturedAudioBuffer) -> [PitchSample] {
        guard buffer.sampleRate > 0,
              analysisWindowSize > 1,
              analysisHopSize > 0,
              buffer.samples.count >= analysisWindowSize else {
            return []
        }

        var observations: [PitchObservation] = []
        var startIndex = 0
        while startIndex + analysisWindowSize <= buffer.samples.count {
            let endIndex = startIndex + analysisWindowSize
            let window = Array(buffer.samples[startIndex..<endIndex])
            let amplitude = rootMeanSquareAmplitude(window)

            if amplitude >= amplitudeThreshold,
               let frequency = estimateFrequency(window: window, sampleRate: buffer.sampleRate) {
                observations.append(
                    PitchObservation(
                        timestamp: Double(startIndex) / buffer.sampleRate,
                        frequency: frequency,
                        amplitude: amplitude
                    )
                )
            }

            startIndex += analysisHopSize
        }

        return track(observations: observations)
    }

    private func rootMeanSquareAmplitude(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sumOfSquares = samples.reduce(0.0) { partialResult, sample in
            let value = Double(sample)
            return partialResult + value * value
        }
        return sqrt(sumOfSquares / Double(samples.count))
    }

    private func estimateFrequency(window: [Float], sampleRate: Double) -> Double? {
        var risingZeroCrossings: [Int] = []

        for index in 1..<window.count {
            if window[index - 1] <= 0, window[index] > 0 {
                risingZeroCrossings.append(index)
            }
        }

        guard risingZeroCrossings.count >= 2 else { return nil }

        let periods = zip(risingZeroCrossings, risingZeroCrossings.dropFirst()).map { previous, current in
            Double(current - previous)
        }
        let averagePeriod = periods.reduce(0.0, +) / Double(periods.count)
        guard averagePeriod > 0 else { return nil }

        return sampleRate / averagePeriod
    }
}
