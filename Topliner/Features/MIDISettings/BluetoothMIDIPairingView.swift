import SwiftUI

struct BluetoothMIDIPairingView: View {
    @Bindable var service: BluetoothMIDIService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(service.pairingInterfaceDescriptor.title)
                .font(.headline)

            Text(service.pairingInterfaceDescriptor.instructions)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Open Bluetooth MIDI Pairing") {
                service.presentPairingInterface()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!service.canPresentPairingInterface)

            Text(service.availabilityMessage)
                .font(.caption)
                .foregroundStyle(service.canPresentPairingInterface ? Color.secondary : Color.red)
        }
        .padding()
        .sheet(isPresented: Binding(
            get: { service.isPairingInterfacePresented },
            set: { isPresented in
                if isPresented {
                    service.presentPairingInterface()
                } else {
                    service.dismissPairingInterface()
                }
            }
        )) {
            BluetoothMIDISystemPairingView(mode: service.pairingInterfaceDescriptor.mode)
        }
    }
}

#if os(iOS) && canImport(CoreAudioKit)
import CoreAudioKit
import UIKit

private struct BluetoothMIDISystemPairingView: UIViewControllerRepresentable {
    var mode: BluetoothMIDIPairingMode

    func makeUIViewController(context: Context) -> UIViewController {
        switch mode {
        case .central:
            return CABTMIDICentralViewController()
        case .localPeripheral:
            return CABTMIDILocalPeripheralViewController()
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#else
private struct BluetoothMIDISystemPairingView: View {
    var mode: BluetoothMIDIPairingMode

    var body: some View {
        VStack(spacing: 12) {
            Text("Bluetooth MIDI")
                .font(.headline)
            Text("System Bluetooth MIDI pairing is only available on iOS devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#endif

#Preview {
    BluetoothMIDIPairingView(service: BluetoothMIDIService())
}
