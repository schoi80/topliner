import SwiftUI

struct NetworkMIDISettingsView: View {
    @Bindable var service: NetworkMIDIService

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Enable Network MIDI", isOn: Binding(
                get: { service.isEnabled },
                set: { service.setEnabled($0) }
            ))
            .disabled(!service.canEnableNetworkMIDI)

            Picker("Connection Policy", selection: Binding(
                get: { service.connectionPolicy },
                set: { service.setConnectionPolicy($0) }
            )) {
                ForEach(NetworkMIDIConnectionPolicy.allCases) { policy in
                    Text(policy.label).tag(policy)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!service.canEnableNetworkMIDI)

            Text(service.instructions)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(service.availabilityMessage)
                .font(.caption)
                .foregroundStyle(service.canEnableNetworkMIDI ? Color.secondary : Color.red)
        }
        .padding()
    }
}

#Preview {
    NetworkMIDISettingsView(service: NetworkMIDIService())
}
