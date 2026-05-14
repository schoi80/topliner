import SwiftUI

struct ComposerSessionControlsView: View {
    @Binding var bpm: Double
    @Binding var barLength: Int
    @Binding var isMetronomeEnabled: Bool

    var body: some View {
        HStack(spacing: 10) {
            Stepper(value: $bpm, in: 40...240, step: 1) {
                StudioControlChip(title: "BPM", value: "\(Int(bpm))", systemImage: "metronome")
            }
            .frame(width: 154)
            .accessibilityIdentifier("topliner.transport.bpm")

            Stepper(value: $barLength, in: 1...16, step: 1) {
                StudioControlChip(title: "Bars", value: "\(barLength)", systemImage: "repeat")
            }
            .frame(width: 150)
            .accessibilityIdentifier("topliner.transport.loop-bars")

            Button {
                isMetronomeEnabled.toggle()
            } label: {
                StudioControlChip(
                    title: "Metro",
                    value: isMetronomeEnabled ? "On" : "Off",
                    systemImage: "speaker.wave.2",
                    isActive: isMetronomeEnabled,
                    tint: StudioTheme.lime
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("topliner.transport.metronome")
        }
    }
}

struct ComposerTransportView: View {
    var projectTitle: String
    @Binding var bpm: Double
    @Binding var barLength: Int
    @Binding var isMetronomeEnabled: Bool
    var quantizeGrid: Double
    var isPlaying: Bool
    var onReset: () -> Void
    var onPlayStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TransportBar(
                state: StudioTransportState(
                    projectTitle: projectTitle,
                    bpm: bpm,
                    barLength: barLength,
                    isMetronomeEnabled: isMetronomeEnabled,
                    snapLabel: snapLabel
                ),
                isPlaying: isPlaying,
                onReset: onReset,
                onPlayStop: onPlayStop,
                onRecord: nil
            )
            .frame(maxWidth: .infinity)

            ComposerSessionControlsView(
                bpm: $bpm,
                barLength: $barLength,
                isMetronomeEnabled: $isMetronomeEnabled
            )
        }
    }

    private var snapLabel: String {
        if quantizeGrid == 0.25 { return "1/16" }
        if quantizeGrid == 0.5 { return "1/8" }
        if quantizeGrid == 1 { return "1/4" }
        return String(format: "%.2f", quantizeGrid)
    }
}
