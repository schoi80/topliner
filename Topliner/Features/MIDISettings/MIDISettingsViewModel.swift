import Foundation
import Observation

@Observable
final class MIDISettingsViewModel {
    var sendLeadNotes: Bool
    var sendChordNotes: Bool
    private(set) var midiChannel: Int
    private(set) var lastTestNoteStatus: String?

    let bluetoothMIDIService: BluetoothMIDIService
    let networkMIDIService: NetworkMIDIService

    private let outputService: MIDIOutputService

    init(
        sendLeadNotes: Bool = true,
        sendChordNotes: Bool = true,
        midiChannel: Int = 0,
        outputService: MIDIOutputService = MIDIOutputService(),
        bluetoothMIDIService: BluetoothMIDIService = BluetoothMIDIService(),
        networkMIDIService: NetworkMIDIService = NetworkMIDIService()
    ) {
        self.sendLeadNotes = sendLeadNotes
        self.sendChordNotes = sendChordNotes
        self.midiChannel = Self.clamp(midiChannel, lower: 0, upper: 15)
        self.outputService = outputService
        self.bluetoothMIDIService = bluetoothMIDIService
        self.networkMIDIService = networkMIDIService
    }

    var displayChannel: Int {
        midiChannel + 1
    }

    var outputRoute: MIDIOutputRoute? {
        switch (sendLeadNotes, sendChordNotes) {
        case (true, true): .both
        case (true, false): .lead
        case (false, true): .chords
        case (false, false): nil
        }
    }

    func setDisplayChannel(_ channel: Int) {
        midiChannel = Self.clamp(channel - 1, lower: 0, upper: 15)
    }

    func sendTestNote() {
        do {
            try outputService.noteOn(pitch: 60, velocity: 96)
            try outputService.noteOff(pitch: 60)
            lastTestNoteStatus = "Sent C4 on channel \(displayChannel)"
        } catch {
            lastTestNoteStatus = "Could not send test note"
        }
    }

    private static func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
