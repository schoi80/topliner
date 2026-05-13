import SwiftUI

struct ComposerEditingToolbar: View {
    var selectedNoteID: UUID?
    var noteCount: Int
    var isPlaying: Bool
    var playbackErrorMessage: String?
    var onDelete: () -> Void
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            StudioControlChip(
                title: "Mode",
                value: selectedNoteID == nil ? "Draw" : "Edit",
                systemImage: selectedNoteID == nil ? "pencil.tip" : "cursorarrow.click",
                isActive: selectedNoteID != nil,
                tint: StudioTheme.cyan
            )

            StudioControlChip(title: "Notes", value: "\(noteCount)", systemImage: "music.note")
            StudioControlChip(title: "Quantize", value: "1/16", systemImage: "grid")
            StudioControlChip(title: "Velocity", value: "100", systemImage: "slider.horizontal.3")
            StudioControlChip(title: "Duration", value: "Beat", systemImage: "arrow.left.and.right")
            StudioControlChip(title: "Nudge", value: "±", systemImage: "arrow.left.arrow.right")

            Spacer(minLength: 8)

            if let playbackErrorMessage {
                Text(playbackErrorMessage)
                    .font(.caption)
                    .foregroundStyle(StudioTheme.danger)
                    .lineLimit(1)
            } else {
                Text(isPlaying ? "Playing local synth" : "Ready")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isPlaying ? StudioTheme.cyan : StudioTheme.textMuted)
                    .lineLimit(1)
            }

            Button("Delete") { onDelete() }
                .disabled(selectedNoteID == nil)
                .buttonStyle(.bordered)
                .tint(.red)

            Button("Clear") { onClear() }
                .disabled(noteCount == 0)
                .buttonStyle(.bordered)
                .tint(.orange)
        }
        .frame(minHeight: StudioLayout.minimumToolbarHeight)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
        )
    }
}
