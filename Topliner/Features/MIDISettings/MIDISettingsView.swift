import SwiftUI

struct MIDISettingsView: View {
    @State var viewModel = MIDISettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StudioLayout.panelSpacing) {
                settingsHeader
                routingPanel
                connectionPanels
            }
            .padding(StudioLayout.screenPadding)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("MIDI Settings")
    }

    private var settingsHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MIDI Routing")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
                Text("Scrollable device setup, styled to match the studio workspace")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.textMuted)
            }

            Spacer(minLength: 12)

            StudioControlChip(title: "Channel", value: "\(viewModel.displayChannel)", systemImage: "number", isActive: true, tint: StudioTheme.cyan)
            StudioControlChip(title: "Output", value: outputRouteLabel, systemImage: "cable.connector", isActive: viewModel.outputRoute != nil, tint: StudioTheme.violet)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
        )
    }

    private var routingPanel: some View {
        StudioPanel("Routing", subtitle: "Choose what Topliner sends to external MIDI destinations") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Send Lead Notes", isOn: $viewModel.sendLeadNotes)
                    .toggleStyle(.switch)
                    .tint(StudioTheme.cyan)
                    .foregroundStyle(StudioTheme.textPrimary)

                Toggle("Send Chord Notes", isOn: $viewModel.sendChordNotes)
                    .toggleStyle(.switch)
                    .tint(StudioTheme.violet)
                    .foregroundStyle(StudioTheme.textPrimary)

                HStack(spacing: 12) {
                    StudioControlChip(title: "MIDI Channel", value: "\(viewModel.displayChannel)", systemImage: "number", isActive: true, tint: StudioTheme.orange)

                    Stepper("", value: Binding(
                        get: { viewModel.displayChannel },
                        set: { viewModel.setDisplayChannel($0) }
                    ), in: 1...16)
                    .labelsHidden()
                    .frame(maxWidth: 150)
                }

                Button {
                    viewModel.sendTestNote()
                } label: {
                    Label("Send Test Note", systemImage: "paperplane.fill")
                        .frame(minHeight: StudioLayout.minimumTouchTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(StudioTheme.cyan)

                if let status = viewModel.lastTestNoteStatus {
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StudioTheme.textSecondary)
                }
            }
        }
    }

    private var connectionPanels: some View {
        HStack(alignment: .top, spacing: StudioLayout.panelSpacing) {
            StudioPanel("Bluetooth MIDI", subtitle: "Pair with iOS-compatible Bluetooth MIDI devices") {
                BluetoothMIDIPairingView(service: viewModel.bluetoothMIDIService)
                    .foregroundStyle(StudioTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .top)

            StudioPanel("Network MIDI", subtitle: "Configure RTP/network MIDI sessions") {
                NetworkMIDISettingsView(service: viewModel.networkMIDIService)
                    .foregroundStyle(StudioTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var outputRouteLabel: String {
        switch viewModel.outputRoute {
        case .both:
            return "Lead + Chords"
        case .lead:
            return "Lead"
        case .chords:
            return "Chords"
        case nil:
            return "Muted"
        }
    }
}

#Preview {
    MIDISettingsView()
}
