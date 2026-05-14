import SwiftUI

struct StudioControlChip: View {
    var title: String
    var value: String?
    var systemImage: String?
    var isActive: Bool = false
    var tint: Color = StudioTheme.cyan

    var body: some View {
        HStack(spacing: 7) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
            }

            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.5)

            if let value {
                Text(value)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(isActive ? Color.black.opacity(0.82) : StudioTheme.textPrimary)
            }
        }
        .lineLimit(1)
        .foregroundStyle(isActive ? Color.black.opacity(0.84) : StudioTheme.textSecondary)
        .padding(.horizontal, 11)
        .frame(minHeight: StudioLayout.minimumTouchTarget)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.controlCornerRadius, style: .continuous)
                .fill(isActive ? tint : StudioTheme.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.controlCornerRadius, style: .continuous)
                .stroke(isActive ? tint.opacity(0.4) : StudioTheme.border, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .contentShape(RoundedRectangle(cornerRadius: StudioLayout.controlCornerRadius, style: .continuous))
    }
}

#Preview {
    HStack {
        StudioControlChip(title: "BPM", value: "124", systemImage: "metronome")
        StudioControlChip(title: "Snap", value: "1/16", systemImage: "grid", isActive: true)
    }
    .padding()
    .studioBackground()
}
