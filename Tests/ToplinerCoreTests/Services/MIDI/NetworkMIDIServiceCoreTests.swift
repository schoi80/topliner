import XCTest
@testable import ToplinerCore

final class NetworkMIDIServiceCoreTests: XCTestCase {
    func testStartsDisabledAndContactsOnlyByDefault() {
        let adapter = RecordingNetworkMIDISessionAdapter()
        let service = NetworkMIDIService(session: adapter)

        XCTAssertFalse(service.isEnabled)
        XCTAssertEqual(service.connectionPolicy, .contactsOnly)
        XCTAssertTrue(service.instructions.contains("Audio MIDI Setup"))
    }

    func testEnableTurnsOnSessionAndAppliesPolicy() {
        let adapter = RecordingNetworkMIDISessionAdapter()
        let service = NetworkMIDIService(session: adapter)

        service.setEnabled(true)

        XCTAssertTrue(service.isEnabled)
        XCTAssertTrue(adapter.isEnabled)
        XCTAssertEqual(adapter.connectionPolicy, .contactsOnly)
    }

    func testDisableTurnsOffSession() {
        let adapter = RecordingNetworkMIDISessionAdapter()
        let service = NetworkMIDIService(session: adapter)
        service.setEnabled(true)

        service.setEnabled(false)

        XCTAssertFalse(service.isEnabled)
        XCTAssertFalse(adapter.isEnabled)
    }

    func testUpdatingConnectionPolicyAppliesToSession() {
        let adapter = RecordingNetworkMIDISessionAdapter()
        let service = NetworkMIDIService(session: adapter)

        service.setConnectionPolicy(.anyone)

        XCTAssertEqual(service.connectionPolicy, .anyone)
        XCTAssertEqual(adapter.connectionPolicy, .anyone)
    }

    func testInstructionsIncludeLocalHostNameWhenAvailable() {
        let adapter = RecordingNetworkMIDISessionAdapter(localName: "Sage iPhone")
        let service = NetworkMIDIService(session: adapter)

        XCTAssertTrue(service.instructions.contains("Sage iPhone"))
        XCTAssertTrue(service.instructions.contains("RTP-MIDI"))
    }

    func testAvailabilityMessageIsExplicitWhenUnavailable() {
        let adapter = RecordingNetworkMIDISessionAdapter(isAvailable: false)
        let service = NetworkMIDIService(session: adapter)

        XCTAssertFalse(service.canEnableNetworkMIDI)
        XCTAssertTrue(service.availabilityMessage.contains("not available"))
        service.setEnabled(true)
        XCTAssertFalse(service.isEnabled)
    }
}

private final class RecordingNetworkMIDISessionAdapter: NetworkMIDISessionManaging {
    var isEnabled: Bool
    var connectionPolicy: NetworkMIDIConnectionPolicy
    let isAvailable: Bool
    let localName: String?

    init(
        isEnabled: Bool = false,
        connectionPolicy: NetworkMIDIConnectionPolicy = .contactsOnly,
        isAvailable: Bool = true,
        localName: String? = nil
    ) {
        self.isEnabled = isEnabled
        self.connectionPolicy = connectionPolicy
        self.isAvailable = isAvailable
        self.localName = localName
    }
}
