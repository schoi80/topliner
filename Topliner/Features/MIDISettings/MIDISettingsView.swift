import SwiftUI

struct MIDISettingsView: View {
    @State var viewModel = MIDISettingsViewModel()

    var body: some View {
        Form {
            Section("Routing") {
                Toggle("Send Lead Notes", isOn: $viewModel.sendLeadNotes)
                Toggle("Send Chord Notes", isOn: $viewModel.sendChordNotes)

                Stepper(
                    "MIDI Channel: \(viewModel.displayChannel)",
                    value: Binding(
                        get: { viewModel.displayChannel },
                        set: { viewModel.setDisplayChannel($0) }
                    ),
                    in: 1...16
                )

                Button("Send Test Note") {
                    viewModel.sendTestNote()
                }

                if let status = viewModel.lastTestNoteStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Bluetooth MIDI") {
                BluetoothMIDIPairingView(service: viewModel.bluetoothMIDIService)
                    .listRowInsets(EdgeInsets())
            }

            Section("Network MIDI") {
                NetworkMIDISettingsView(service: viewModel.networkMIDIService)
                    .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle("MIDI Settings")
    }
}

#Preview {
    NavigationStack {
        MIDISettingsView()
    }
}
