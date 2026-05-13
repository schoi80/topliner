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

    func testStopRecordingStoresCapturedBufferAndClearsRecordingState() {
        let expectedBuffer = CapturedAudioBuffer(samples: [0.1, -0.2, 0.3], sampleRate: 44_100)
        let recorder = MockAudioRecorder(permissionResult: .granted, stopResult: expectedBuffer)
        let viewModel = AudioCaptureViewModel(recorder: recorder)
        viewModel.startRecording()

        viewModel.stopRecording()

        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.capturedBuffer, expectedBuffer)
        XCTAssertEqual(recorder.stopCallCount, 1)
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
