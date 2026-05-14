import SwiftUI

struct NetworkMIDISettingsView: View {
    @Bindable var service: NetworkMIDIService
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            Toggle("Enable Network MIDI", isOn: Binding(
                get: { service.isEnabled },
                set: { service.setEnabled($0) }
            ))
            .disabled(!service.canEnableNetworkMIDI)
            .frame(minHeight: StudioLayout.minimumTouchTarget)

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
                .lineLimit(compact ? 4 : nil)
                .foregroundStyle(.secondary)

            Text(service.availabilityMessage)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(service.canEnableNetworkMIDI ? Color.secondary : Color.red)
        }
        .padding(compact ? 0 : 16)
    }
}

#Preview {
    NetworkMIDISettingsView(service: NetworkMIDIService())
}
