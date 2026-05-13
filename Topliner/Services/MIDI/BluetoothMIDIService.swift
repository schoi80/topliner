import Foundation
import Observation

enum BluetoothMIDIPairingMode: Equatable {
    case central
    case localPeripheral
}

struct BluetoothMIDIPairingInterfaceDescriptor: Equatable {
    var mode: BluetoothMIDIPairingMode
    var title: String
    var instructions: String
}

@Observable
final class BluetoothMIDIService {
    private let isBluetoothMIDIAvailable: Bool
    private let pairingMode: BluetoothMIDIPairingMode

    private(set) var isPairingInterfacePresented: Bool

    init(
        pairingMode: BluetoothMIDIPairingMode = .central,
        isBluetoothMIDIAvailable: Bool = true,
        isPairingInterfacePresented: Bool = false
    ) {
        self.pairingMode = pairingMode
        self.isBluetoothMIDIAvailable = isBluetoothMIDIAvailable
        self.isPairingInterfacePresented = isPairingInterfacePresented
    }

    var canPresentPairingInterface: Bool {
        isBluetoothMIDIAvailable
    }

    var pairingInstructions: String {
        switch pairingMode {
        case .central:
            "Put your Bluetooth MIDI device in pairing mode, open the pairing sheet, then select it from the system list."
        case .localPeripheral:
            "Advertise this iPhone as a Bluetooth MIDI peripheral, then connect from your DAW or host."
        }
    }

    var availabilityMessage: String {
        if isBluetoothMIDIAvailable {
            "Bluetooth MIDI pairing is available on this device."
        } else {
            "Bluetooth MIDI pairing is not available on this device."
        }
    }

    var pairingInterfaceDescriptor: BluetoothMIDIPairingInterfaceDescriptor {
        BluetoothMIDIPairingInterfaceDescriptor(
            mode: pairingMode,
            title: "Bluetooth MIDI",
            instructions: pairingInstructions
        )
    }

    func presentPairingInterface() {
        guard canPresentPairingInterface else { return }
        isPairingInterfacePresented = true
    }

    func dismissPairingInterface() {
        isPairingInterfacePresented = false
    }
}
