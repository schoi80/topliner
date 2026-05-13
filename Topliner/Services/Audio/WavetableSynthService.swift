import AudioKit
import Foundation
import Observation
import SoundpipeAudioKit

struct SynthEnvelope: Equatable {
    var attackDuration: Double
    var decayDuration: Double
    var sustainLevel: Double
    var releaseDuration: Double

    static let `default` = SynthEnvelope(
        attackDuration: 0.01,
        decayDuration: 0.08,
        sustainLevel: 0.8,
        releaseDuration: 0.15
    )
}

protocol SynthVoiceManaging: AnyObject {
    func noteOn(pitch: Int, frequency: Double, amplitude: Double, envelope: SynthEnvelope)
    func noteOff(pitch: Int)
}

@Observable
final class WavetableSynthService {
    private let voice: SynthVoiceManaging
    private let envelope: SynthEnvelope
    private(set) var activePitches: Set<Int>

    init(
        voice: SynthVoiceManaging = AudioKitWavetableVoiceManager(),
        envelope: SynthEnvelope = .default
    ) {
        self.voice = voice
        self.envelope = envelope
        activePitches = []
    }

    func noteOn(pitch: Int, velocity: Int) {
        let amplitude = normalizedAmplitude(for: velocity)
        let frequency = Self.frequency(forMIDINote: pitch)

        voice.noteOn(
            pitch: pitch,
            frequency: frequency,
            amplitude: amplitude,
            envelope: envelope
        )
        activePitches.insert(pitch)
    }

    func noteOff(pitch: Int) {
        voice.noteOff(pitch: pitch)
        activePitches.remove(pitch)
    }

    func play(chord: ChordEvent, velocity: Int = 90) {
        chord.midiNotes.forEach { noteOn(pitch: $0, velocity: velocity) }
    }

    static func frequency(forMIDINote pitch: Int) -> Double {
        440.0 * pow(2.0, Double(pitch - 69) / 12.0)
    }

    private func normalizedAmplitude(for velocity: Int) -> Double {
        let clampedVelocity = min(max(velocity, 0), 127)
        return Double(clampedVelocity) / 127.0
    }
}

final class AudioKitWavetableVoiceManager: SynthVoiceManaging {
    private struct ActiveVoice {
        var oscillator: Oscillator
        var envelope: AmplitudeEnvelope
    }

    private let mixer: Mixer
    private var activeVoices: [Int: ActiveVoice]

    var outputNode: Node { mixer }

    init(mixer: Mixer = Mixer()) {
        self.mixer = mixer
        activeVoices = [:]
    }

    func noteOn(pitch: Int, frequency: Double, amplitude: Double, envelope: SynthEnvelope) {
        noteOff(pitch: pitch)

        let oscillator = Oscillator(
            waveform: Table(.sine),
            frequency: AUValue(frequency),
            amplitude: AUValue(amplitude)
        )
        let amplitudeEnvelope = AmplitudeEnvelope(
            oscillator,
            attackDuration: AUValue(envelope.attackDuration),
            decayDuration: AUValue(envelope.decayDuration),
            sustainLevel: AUValue(envelope.sustainLevel),
            releaseDuration: AUValue(envelope.releaseDuration)
        )

        mixer.addInput(amplitudeEnvelope)
        oscillator.start()
        amplitudeEnvelope.start()
        activeVoices[pitch] = ActiveVoice(oscillator: oscillator, envelope: amplitudeEnvelope)
    }

    func noteOff(pitch: Int) {
        guard let activeVoice = activeVoices.removeValue(forKey: pitch) else { return }
        activeVoice.envelope.stop()
        activeVoice.oscillator.stop()
        mixer.removeInput(activeVoice.envelope)
    }
}
