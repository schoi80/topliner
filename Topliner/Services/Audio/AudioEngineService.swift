import AudioKit
import Foundation
import Observation

#if os(iOS)
import AVFAudio
#endif

protocol AudioSessionManaging: AnyObject {
    func configureForPlayback() throws
}

protocol AudioEngineManaging: AnyObject {
    func start() throws
    func stop()
}

protocol AudioEnginePlaybackManaging: AnyObject {
    var isRunning: Bool { get }

    func start() throws
    func stop()
}

@Observable
final class AudioEngineService: AudioEnginePlaybackManaging {
    private let session: AudioSessionManaging
    private let engine: AudioEngineManaging

    private(set) var isConfigured: Bool
    private(set) var isRunning: Bool
    private(set) var lastErrorMessage: String?

    init(
        session: AudioSessionManaging = SystemAudioSessionManager(),
        engine: AudioEngineManaging = AudioKitEngineManager()
    ) {
        self.session = session
        self.engine = engine
        isConfigured = false
        isRunning = false
        lastErrorMessage = nil
    }

    func start() throws {
        guard !isRunning else { return }

        do {
            if !isConfigured {
                try session.configureForPlayback()
                isConfigured = true
            }

            try engine.start()
            isRunning = true
            lastErrorMessage = nil
        } catch {
            isRunning = false
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
    }
}

final class SystemAudioSessionManager: AudioSessionManaging {
    func configureForPlayback() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif
    }
}

final class AudioKitEngineManager: AudioEngineManaging {
    private let engine: AudioEngine
    private let outputMixer: Mixer

    init(engine: AudioEngine = AudioEngine(), inputs: [Node] = []) {
        self.engine = engine
        outputMixer = Mixer()
        inputs.forEach { outputMixer.addInput($0) }
        self.engine.output = outputMixer
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}
