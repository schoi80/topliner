import XCTest
@testable import ToplinerCore

final class BluetoothMIDIServiceCoreTests: XCTestCase {
    func testInstructionsDescribePairingFlowForBLEMIDIDevices() {
        let service = BluetoothMIDIService()

        XCTAssertTrue(service.pairingInstructions.contains("Bluetooth MIDI"))
        XCTAssertTrue(service.pairingInstructions.contains("device in pairing mode"))
        XCTAssertTrue(service.pairingInstructions.contains("select it from the system list"))
    }

    func testPresentationStateTracksPairingSheetLifecycle() {
        let service = BluetoothMIDIService()

        XCTAssertFalse(service.isPairingInterfacePresented)

        service.presentPairingInterface()
        XCTAssertTrue(service.isPairingInterfacePresented)

        service.dismissPairingInterface()
        XCTAssertFalse(service.isPairingInterfacePresented)
    }

    func testDefaultDescriptorUsesCentralPairingInterface() {
        let service = BluetoothMIDIService()

        XCTAssertEqual(service.pairingInterfaceDescriptor.mode, .central)
        XCTAssertEqual(service.pairingInterfaceDescriptor.title, "Bluetooth MIDI")
    }

    func testLocalPeripheralDescriptorCanBeSelectedForHostPairing() {
        let service = BluetoothMIDIService(pairingMode: .localPeripheral)

        XCTAssertEqual(service.pairingInterfaceDescriptor.mode, .localPeripheral)
        XCTAssertTrue(service.pairingInterfaceDescriptor.instructions.contains("DAW or host"))
    }

    func testAvailabilityMessageIsExplicitWhenUnavailable() {
        let service = BluetoothMIDIService(isBluetoothMIDIAvailable: false)

        XCTAssertFalse(service.canPresentPairingInterface)
        XCTAssertTrue(service.availabilityMessage.contains("not available"))
    }
}
