import SwiftUI

struct TransportBar: View {
    var state: StudioTransportState
    var isPlaying: Bool
    var onReset: () -> Void
    var onPlayStop: () -> Void
    var onRecord: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOPLINER")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(StudioTheme.violet)

                Text(state.projectTitle)
                    .font(.caption2)
                    .foregroundStyle(StudioTheme.textMuted)
            }
            .frame(width: 132, alignment: .leading)

            HStack(spacing: 8) {
                TransportIconButton(systemImage: "backward.end.fill", accessibilityLabel: "Reset", action: onReset)
                TransportIconButton(systemImage: isPlaying ? "stop.fill" : "play.fill", accessibilityLabel: isPlaying ? "Stop" : "Play", tint: StudioTheme.cyan, action: onPlayStop)

                if let onRecord {
                    TransportIconButton(systemImage: "record.circle", accessibilityLabel: "Record", tint: StudioTheme.danger, action: onRecord)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                StudioControlChip(title: "Tempo", value: state.bpmLabel, systemImage: "metronome")
                StudioControlChip(title: "Loop", value: state.barLengthLabel, systemImage: "repeat")
                StudioControlChip(title: "Length", value: state.loopLengthLabel, systemImage: "timeline.selection")
                StudioControlChip(title: "Metro", value: state.isMetronomeEnabled ? "On" : "Off", systemImage: "speaker.wave.2", isActive: state.isMetronomeEnabled, tint: StudioTheme.lime)
                StudioControlChip(title: "Snap", value: state.snapLabel, systemImage: "grid", isActive: true, tint: StudioTheme.violet)
            }
        }
        .frame(minHeight: StudioLayout.minimumTransportHeight)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
        )
    }
}

private struct TransportIconButton: View {
    var systemImage: String
    var accessibilityLabel: String
    var tint: Color = StudioTheme.textSecondary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .frame(width: StudioLayout.minimumTouchTarget, height: StudioLayout.minimumTouchTarget)
                .foregroundStyle(tint)
                .background(
                    RoundedRectangle(cornerRadius: StudioLayout.controlCornerRadius, style: .continuous)
                        .fill(StudioTheme.elevatedSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: StudioLayout.controlCornerRadius, style: .continuous)
                        .stroke(StudioTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    TransportBar(
        state: StudioTransportState(projectTitle: "Neon Drift", bpm: 124, barLength: 4, isMetronomeEnabled: true, snapLabel: "1/16"),
        isPlaying: false,
        onReset: {},
        onPlayStop: {},
        onRecord: {}
    )
    .padding()
    .studioBackground()
}
