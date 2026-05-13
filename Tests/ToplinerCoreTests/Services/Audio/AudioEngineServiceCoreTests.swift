import XCTest
@testable import ToplinerCore

final class AudioEngineServiceCoreTests: XCTestCase {
    func testStartsStoppedAndUnconfigured() {
        let session = MockAudioSessionManager()
        let engine = MockAudioEngineManager()
        let service = AudioEngineService(session: session, engine: engine)

        XCTAssertFalse(service.isConfigured)
        XCTAssertFalse(service.isRunning)
        XCTAssertNil(service.lastErrorMessage)
        XCTAssertFalse(session.didConfigureForPlayback)
        XCTAssertFalse(engine.didStart)
    }

    func testStartConfiguresSessionAndStartsEngine() throws {
        let session = MockAudioSessionManager()
        let engine = MockAudioEngineManager()
        let service = AudioEngineService(session: session, engine: engine)

        try service.start()

        XCTAssertTrue(session.didConfigureForPlayback)
        XCTAssertTrue(engine.didStart)
        XCTAssertTrue(service.isConfigured)
        XCTAssertTrue(service.isRunning)
        XCTAssertNil(service.lastErrorMessage)
    }

    func testStartIsIdempotentWhileRunning() throws {
        let session = MockAudioSessionManager()
        let engine = MockAudioEngineManager()
        let service = AudioEngineService(session: session, engine: engine)

        try service.start()
        try service.start()

        XCTAssertEqual(session.configureCallCount, 1)
        XCTAssertEqual(engine.startCallCount, 1)
    }

    func testStopStopsEngineAndClearsRunningState() throws {
        let session = MockAudioSessionManager()
        let engine = MockAudioEngineManager()
        let service = AudioEngineService(session: session, engine: engine)

        try service.start()
        service.stop()

        XCTAssertTrue(engine.didStop)
        XCTAssertFalse(service.isRunning)
        XCTAssertTrue(service.isConfigured)
    }

    func testStartFailureSurfacesErrorAndDoesNotMarkRunning() {
        let session = MockAudioSessionManager()
        let engine = MockAudioEngineManager(startError: StubAudioError.startFailed)
        let service = AudioEngineService(session: session, engine: engine)

        XCTAssertThrowsError(try service.start()) { error in
            XCTAssertEqual(error as? StubAudioError, .startFailed)
        }

        XCTAssertTrue(session.didConfigureForPlayback)
        XCTAssertTrue(service.isConfigured)
        XCTAssertFalse(service.isRunning)
        XCTAssertEqual(service.lastErrorMessage, StubAudioError.startFailed.localizedDescription)
    }
}

private enum StubAudioError: LocalizedError, Equatable {
    case startFailed

    var errorDescription: String? {
        "Start failed"
    }
}

private final class MockAudioSessionManager: AudioSessionManaging {
    private(set) var didConfigureForPlayback = false
    private(set) var configureCallCount = 0

    func configureForPlayback() throws {
        didConfigureForPlayback = true
        configureCallCount += 1
    }
}

private final class MockAudioEngineManager: AudioEngineManaging {
    private(set) var didStart = false
    private(set) var didStop = false
    private(set) var startCallCount = 0
    private let startError: Error?

    init(startError: Error? = nil) {
        self.startError = startError
    }

    func start() throws {
        startCallCount += 1
        if let startError {
            throw startError
        }
        didStart = true
    }

    func stop() {
        didStop = true
    }
}
