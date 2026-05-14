import SwiftUI

struct BluetoothMIDIPairingView: View {
    @Bindable var service: BluetoothMIDIService
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 16) {
            Text(service.pairingInterfaceDescriptor.title)
                .font(compact ? .subheadline.weight(.semibold) : .headline)

            Text(service.pairingInterfaceDescriptor.instructions)
                .font(compact ? .caption : .subheadline)
                .lineLimit(compact ? 4 : nil)
                .foregroundStyle(.secondary)

            Button("Open Bluetooth MIDI Pairing") {
                service.presentPairingInterface()
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: StudioLayout.minimumTouchTarget)
            .disabled(!service.canPresentPairingInterface)
            .accessibilityIdentifier("topliner.midi.bluetooth.pair")

            Text(service.availabilityMessage)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(service.canPresentPairingInterface ? Color.secondary : Color.red)
        }
        .padding(compact ? 0 : 16)
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
