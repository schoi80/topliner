import XCTest
@testable import ToplinerCore

final class MIDISettingsViewModelCoreTests: XCTestCase {
    func testDefaultsSendLeadAndChordsOnChannelOne() {
        let viewModel = MIDISettingsViewModel()

        XCTAssertTrue(viewModel.sendLeadNotes)
        XCTAssertTrue(viewModel.sendChordNotes)
        XCTAssertEqual(viewModel.midiChannel, 0)
        XCTAssertEqual(viewModel.displayChannel, 1)
        XCTAssertEqual(viewModel.outputRoute, .both)
    }

    func testRouteReflectsLeadAndChordToggles() {
        let viewModel = MIDISettingsViewModel()

        viewModel.sendChordNotes = false
        XCTAssertEqual(viewModel.outputRoute, .lead)

        viewModel.sendLeadNotes = false
        XCTAssertNil(viewModel.outputRoute)

        viewModel.sendChordNotes = true
        XCTAssertEqual(viewModel.outputRoute, .chords)
    }

    func testSetDisplayChannelClampsToMidiRangeAndStoresZeroBasedChannel() {
        let viewModel = MIDISettingsViewModel()

        viewModel.setDisplayChannel(20)
        XCTAssertEqual(viewModel.midiChannel, 15)
        XCTAssertEqual(viewModel.displayChannel, 16)

        viewModel.setDisplayChannel(-3)
        XCTAssertEqual(viewModel.midiChannel, 0)
        XCTAssertEqual(viewModel.displayChannel, 1)
    }

    func testTestNoteSendsMiddleCAndStoresStatus() throws {
        let sink = RecordingMIDIPacketSink()
        let service = MIDIOutputService(sink: sink, channel: 3)
        let viewModel = MIDISettingsViewModel(midiChannel: 3, outputService: service)

        viewModel.sendTestNote()

        XCTAssertEqual(sink.packets, [[0x93, 60, 96], [0x83, 60, 0]])
        XCTAssertEqual(viewModel.lastTestNoteStatus, "Sent C4 on channel 4")
    }

    func testBluetoothAndNetworkServicesAreAvailableForSettingsView() {
        let viewModel = MIDISettingsViewModel()

        XCTAssertFalse(viewModel.bluetoothMIDIService.isPairingInterfacePresented)
        XCTAssertFalse(viewModel.networkMIDIService.isEnabled)
    }
}

private final class RecordingMIDIPacketSink: MIDIPacketSending {
    var packets: [[UInt8]] = []

    func send(packet: [UInt8]) throws {
        packets.append(packet)
    }
}
