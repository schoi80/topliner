import XCTest
@testable import ToplinerCore

final class AudioCaptureViewModelCoreTests: XCTestCase {
    func testStartsIdleWithUnknownPermissionAndNoBuffer() {
        let recorder = MockAudioRecorder()
        let viewModel = AudioCaptureViewModel(recorder: recorder)

        XCTAssertEqual(viewModel.permissionStatus, .unknown)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.capturedBuffer)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCaptureSessionControlsClampBPMAndCountIn() {
        let viewModel = AudioCaptureViewModel()

        viewModel.bpm = 400
        viewModel.countInBars = 8
        viewModel.isMetronomeEnabled = true

        XCTAssertEqual(viewModel.bpm, 240)
        XCTAssertEqual(viewModel.countInBars, 4)
        XCTAssertTrue(viewModel.isMetronomeEnabled)
    }

    func testStopRecordingSegmentsUsingSessionBPM() {
        let buffer = CapturedAudioBuffer(samples: [0.1, 0.2, 0.3], sampleRate: 44_100)
        let recorder = MockAudioRecorder(permissionResult: .granted, stopResult: buffer)
        let pitchTrace = [PitchSample(timestamp: 0.0, frequency: 440.0, midiNote: 69, amplitude: 0.5)]
        let segmenter = MockPitchTraceSegmenter(notesToReturn: [])
        let viewModel = AudioCaptureViewModel(
            recorder: recorder,
            pitchTracker: MockPitchTracker(samplesToReturn: pitchTrace),
            pitchSegmenter: segmenter,
            permissionStatus: .granted
        )
        viewModel.bpm = 96

        viewModel.startRecording()
        viewModel.stopRecording()

        XCTAssertEqual(segmenter.segmentCalls, [PitchTraceSegmenterCall(trace: pitchTrace, bpm: 96)])
    }

    func testRequestPermissionStoresGrantedStatus() {
        let recorder = MockAudioRecorder(permissionResult: .granted)
        let viewModel = AudioCaptureViewModel(recorder: recorder)

        viewModel.requestPermission()

        XCTAssertEqual(viewModel.permissionStatus, .granted)
        XCTAssertEqual(recorder.requestPermissionCallCount, 1)
    }

    func testStartRecordingRequestsPermissionAndStartsRecorderWhenGranted() {
        let recorder = MockAudioRecorder(permissionResult: .granted)
        let viewModel = AudioCaptureViewModel(recorder: recorder)

        viewModel.startRecording()

        XCTAssertEqual(viewModel.permissionStatus, .granted)
        XCTAssertTrue(viewModel.isRecording)
        XCTAssertEqual(recorder.startCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStartRecordingDoesNotStartRecorderWhenPermissionDenied() {
        let recorder = MockAudioRecorder(permissionResult: .denied)
        let viewModel = AudioCaptureViewModel(recorder: recorder)

        viewModel.startRecording()

        XCTAssertEqual(viewModel.permissionStatus, .denied)
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(recorder.startCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Microphone permission is required to record audio.")
    }

    func testStopRecordingStoresCapturedBufferTranscribesPitchTraceAndClearsRecordingState() {
        let buffer = CapturedAudioBuffer(samples: [0.1, 0.2, 0.3], sampleRate: 44_100)
        let recorder = MockAudioRecorder(permissionResult: .granted, stopResult: buffer)
        let pitchTrace = [
            PitchSample(timestamp: 0.0, frequency: 440.0, midiNote: 69, amplitude: 0.5)
        ]
        let draftNotes = [
            MIDINoteEvent(pitch: 69, startBeat: 0.0, durationBeats: 0.5, velocity: 96)
        ]
        let pitchTracker = MockPitchTracker(samplesToReturn: pitchTrace)
        let segmenter = MockPitchTraceSegmenter(notesToReturn: draftNotes)
        let viewModel = AudioCaptureViewModel(
            recorder: recorder,
            pitchTracker: pitchTracker,
            pitchSegmenter: segmenter,
            permissionStatus: .granted
        )

        viewModel.startRecording()
        viewModel.stopRecording()

        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.capturedBuffer, buffer)
        XCTAssertEqual(viewModel.pitchTrace, pitchTracker.samplesToReturn)
        XCTAssertEqual(viewModel.draftMIDINotes, draftNotes)
        XCTAssertEqual(pitchTracker.buffersTracked, [buffer])
        XCTAssertEqual(segmenter.segmentCalls, [PitchTraceSegmenterCall(trace: pitchTrace, bpm: 120)])
    }

    func testToggleRecordingStartsThenStops() {
        let expectedBuffer = CapturedAudioBuffer(samples: [0.5], sampleRate: 48_000)
        let recorder = MockAudioRecorder(permissionResult: .granted, stopResult: expectedBuffer)
        let viewModel = AudioCaptureViewModel(recorder: recorder)

        viewModel.toggleRecording()
        XCTAssertTrue(viewModel.isRecording)

        viewModel.toggleRecording()
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.capturedBuffer, expectedBuffer)
    }
}

private final class MockAudioRecorder: AudioRecordingManaging {
    var permissionResult: MicrophonePermissionStatus
    var stopResult: CapturedAudioBuffer?
    private(set) var requestPermissionCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(permissionResult: MicrophonePermissionStatus = .unknown, stopResult: CapturedAudioBuffer? = nil) {
        self.permissionResult = permissionResult
        self.stopResult = stopResult
    }

    func requestMicrophonePermission() -> MicrophonePermissionStatus {
        requestPermissionCallCount += 1
        return permissionResult
    }

    func startRecording() throws {
        startCallCount += 1
    }

    func stopRecording() -> CapturedAudioBuffer? {
        stopCallCount += 1
        return stopResult
    }
}

private final class MockPitchTracker: PitchTrackingManaging {
    var samplesToReturn: [PitchSample]
    private(set) var buffersTracked: [CapturedAudioBuffer] = []

    init(samplesToReturn: [PitchSample]) {
        self.samplesToReturn = samplesToReturn
    }

    func track(buffer: CapturedAudioBuffer) -> [PitchSample] {
        buffersTracked.append(buffer)
        return samplesToReturn
    }
}

private struct PitchTraceSegmenterCall: Equatable {
    var trace: [PitchSample]
    var bpm: Double
}

private final class MockPitchTraceSegmenter: PitchTraceSegmenting {
    var notesToReturn: [MIDINoteEvent]
    private(set) var segmentCalls: [PitchTraceSegmenterCall] = []

    init(notesToReturn: [MIDINoteEvent]) {
        self.notesToReturn = notesToReturn
    }

    func segment(trace: [PitchSample], bpm: Double) -> [MIDINoteEvent] {
        segmentCalls.append(PitchTraceSegmenterCall(trace: trace, bpm: bpm))
        return notesToReturn
    }
}
