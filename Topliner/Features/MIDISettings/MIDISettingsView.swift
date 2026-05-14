import SwiftUI

struct MIDISettingsView: View {
    @State var viewModel = MIDISettingsViewModel()

    var body: some View {
        GeometryReader { proxy in
            let layout = MIDISettingsLandscapeLayout(
                availableWidth: proxy.size.width,
                availableHeight: proxy.size.height
            )

            ScrollView {
                VStack(alignment: .leading, spacing: layout.verticalSpacing) {
                    settingsHeader(layout: layout)
                    settingsGrid(layout: layout)
                }
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .background(StudioTheme.background.ignoresSafeArea())
    }

    private func settingsHeader(layout: MIDISettingsLandscapeLayout) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MIDI Routing")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
                Text("Device setup for sending lead and harmony tracks to external MIDI destinations")
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(StudioTheme.textMuted)
            }

            Spacer(minLength: 8)

            StudioControlChip(title: "Channel", value: "\(viewModel.displayChannel)", systemImage: "number", isActive: true, tint: StudioTheme.cyan)
            StudioControlChip(title: "Output", value: outputRouteLabel, systemImage: "cable.connector", isActive: viewModel.outputRoute != nil, tint: StudioTheme.violet)
        }
        .padding(.horizontal, layout.panelPadding)
        .frame(minHeight: 58)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private func settingsGrid(layout: MIDISettingsLandscapeLayout) -> some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.fixed(layout.contentColumnWidth), spacing: layout.panelSpacing, alignment: .top),
                count: layout.columnCount
            ),
            alignment: .leading,
            spacing: layout.panelSpacing
        ) {
            routingPanel(layout: layout)
            bluetoothPanel(layout: layout)
            networkPanel(layout: layout)
        }
    }

    private func routingPanel(layout: MIDISettingsLandscapeLayout) -> some View {
        StudioPanel("Routing", subtitle: "Choose tracks and output channel", padding: layout.panelPadding) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Output Route")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textMuted)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                    spacing: 8
                ) {
                    ForEach(MIDIOutputRouteChoice.allCases) { choice in
                        midiRouteButton(choice: choice, minimumHeight: layout.minimumControlHeight)
                    }
                }

                HStack(spacing: 10) {
                    StudioControlChip(title: "MIDI Channel", value: "\(viewModel.displayChannel)", systemImage: "number", isActive: true, tint: StudioTheme.orange)

                    Stepper("", value: Binding(
                        get: { viewModel.displayChannel },
                        set: { viewModel.setDisplayChannel($0) }
                    ), in: 1...16)
                    .labelsHidden()
                    .frame(maxWidth: 132)
                    .accessibilityIdentifier("topliner.midi.channel.stepper")
                }

                Button {
                    viewModel.sendTestNote()
                } label: {
                    Label("Send Test Note", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: layout.minimumControlHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(StudioTheme.cyan)
                .accessibilityIdentifier("topliner.midi.test-note")

                if let status = viewModel.lastTestNoteStatus {
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(StudioTheme.textSecondary)
                }
            }
        }
    }

    private func midiRouteButton(choice: MIDIOutputRouteChoice, minimumHeight: CGFloat) -> some View {
        let isActive = choice.matches(viewModel.outputRoute)
        return Button {
            viewModel.setOutputRoute(choice.route)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: choice.systemImage)
                    .font(.caption.weight(.bold))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(choice.title)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                    Text(choice.subtitle)
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(StudioTheme.textMuted)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(isActive ? StudioTheme.background : StudioTheme.textPrimary)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? choice.tint : StudioTheme.surface.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? choice.tint.opacity(0.7) : StudioTheme.border, lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(choice.accessibilityIdentifier)
    }

    private func bluetoothPanel(layout: MIDISettingsLandscapeLayout) -> some View {
        StudioPanel("Bluetooth MIDI", subtitle: "Pair with iOS-compatible devices", padding: layout.panelPadding) {
            BluetoothMIDIPairingView(service: viewModel.bluetoothMIDIService, compact: true)
                .foregroundStyle(StudioTheme.textPrimary)
        }
    }

    private func networkPanel(layout: MIDISettingsLandscapeLayout) -> some View {
        StudioPanel("Network MIDI", subtitle: "Configure RTP/network sessions", padding: layout.panelPadding) {
            NetworkMIDISettingsView(service: viewModel.networkMIDIService, compact: true)
                .foregroundStyle(StudioTheme.textPrimary)
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

private enum MIDIOutputRouteChoice: String, CaseIterable, Identifiable {
    case both
    case lead
    case chords
    case muted

    var id: String { rawValue }

    var route: MIDIOutputRoute? {
        switch self {
        case .both: .both
        case .lead: .lead
        case .chords: .chords
        case .muted: nil
        }
    }

    var title: String {
        switch self {
        case .both: "Lead + Chords"
        case .lead: "Lead"
        case .chords: "Chords"
        case .muted: "Muted"
        }
    }

    var subtitle: String {
        switch self {
        case .both: "Full song"
        case .lead: "Melody only"
        case .chords: "Harmony only"
        case .muted: "No output"
        }
    }

    var systemImage: String {
        switch self {
        case .both: "rectangle.3.group.fill"
        case .lead: "waveform"
        case .chords: "pianokeys"
        case .muted: "speaker.slash.fill"
        }
    }

    var tint: Color {
        switch self {
        case .both: StudioTheme.cyan
        case .lead: StudioTheme.violet
        case .chords: StudioTheme.orange
        case .muted: StudioTheme.textMuted
        }
    }

    var accessibilityIdentifier: String {
        "topliner.midi.route.\(rawValue)"
    }

    func matches(_ route: MIDIOutputRoute?) -> Bool {
        switch (self, route) {
        case (.both, .both), (.lead, .lead), (.chords, .chords), (.muted, nil): true
        default: false
        }
    }
}

#Preview {
    MIDISettingsView()
}
