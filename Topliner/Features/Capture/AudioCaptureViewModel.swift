import Foundation
import Observation

#if os(iOS)
import AVFAudio
#endif

enum MicrophonePermissionStatus: Equatable {
    case unknown
    case granted
    case denied
}

struct CapturedAudioBuffer: Equatable {
    var samples: [Float]
    var sampleRate: Double
}

protocol AudioRecordingManaging: AnyObject {
    func requestMicrophonePermission() -> MicrophonePermissionStatus
    func startRecording() throws
    func stopRecording() -> CapturedAudioBuffer?
}

@Observable
final class AudioCaptureViewModel {
    private let recorder: AudioRecordingManaging
    private let pitchTracker: PitchTrackingManaging

    private(set) var permissionStatus: MicrophonePermissionStatus
    private(set) var isRecording: Bool
    private(set) var capturedBuffer: CapturedAudioBuffer?
    private(set) var pitchTrace: [PitchSample]
    private(set) var errorMessage: String?

    init(
        recorder: AudioRecordingManaging = SystemAudioRecorder(),
        pitchTracker: PitchTrackingManaging = PitchTrackingService(),
        permissionStatus: MicrophonePermissionStatus = .unknown,
        isRecording: Bool = false,
        capturedBuffer: CapturedAudioBuffer? = nil,
        pitchTrace: [PitchSample] = [],
        errorMessage: String? = nil
    ) {
        self.recorder = recorder
        self.pitchTracker = pitchTracker
        self.permissionStatus = permissionStatus
        self.isRecording = isRecording
        self.capturedBuffer = capturedBuffer
        self.pitchTrace = pitchTrace
        self.errorMessage = errorMessage
    }

    func requestPermission() {
        permissionStatus = recorder.requestMicrophonePermission()
    }

    func startRecording() {
        if permissionStatus != .granted {
            requestPermission()
        }

        guard permissionStatus == .granted else {
            isRecording = false
            errorMessage = "Microphone permission is required to record audio."
            return
        }

        do {
            try recorder.startRecording()
            capturedBuffer = nil
            pitchTrace = []
            errorMessage = nil
            isRecording = true
        } catch {
            isRecording = false
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        let buffer = recorder.stopRecording()
        capturedBuffer = buffer
        pitchTrace = buffer.map { pitchTracker.track(buffer: $0) } ?? []
        isRecording = false
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}

final class SystemAudioRecorder: AudioRecordingManaging {
    #if os(iOS)
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private var sampleRate: Double = 44_100
    #endif

    func requestMicrophonePermission() -> MicrophonePermissionStatus {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                let semaphore = DispatchSemaphore(value: 0)
                var granted = false
                AVAudioApplication.requestRecordPermission { isGranted in
                    granted = isGranted
                    semaphore.signal()
                }
                semaphore.wait()
                return granted ? .granted : .denied
            @unknown default:
                return .unknown
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                return .granted
            case .denied:
                return .denied
            case .undetermined:
                let semaphore = DispatchSemaphore(value: 0)
                var granted = false
                session.requestRecordPermission { isGranted in
                    granted = isGranted
                    semaphore.signal()
                }
                semaphore.wait()
                return granted ? .granted : .denied
            @unknown default:
                return .unknown
            }
        }
        #else
        return .denied
        #endif
    }

    func startRecording() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        samples.removeAll()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            guard let self, let channel = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            self.samples.append(contentsOf: UnsafeBufferPointer(start: channel, count: frameCount))
        }

        engine.prepare()
        try engine.start()
        #endif
    }

    func stopRecording() -> CapturedAudioBuffer? {
        #if os(iOS)
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        return CapturedAudioBuffer(samples: samples, sampleRate: sampleRate)
        #else
        return nil
        #endif
    }
}
