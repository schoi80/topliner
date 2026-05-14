import SwiftUI

struct StudioPanel<Content: View>: View {
    private let title: String?
    private let subtitle: String?
    private let content: Content

    init(
        _ title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 3) {
                    if let title {
                        Text(title.uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(StudioTheme.textPrimary)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(StudioTheme.textMuted)
                    }
                }
            }

            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .fill(StudioTheme.panel.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: StudioLayout.panelCornerRadius, style: .continuous)
                .stroke(StudioTheme.border, lineWidth: 1)
        )
    }
}

#Preview {
    StudioPanel("Harmony", subtitle: "Chord generation") {
        Text("Neo Soul · Advanced")
            .foregroundStyle(StudioTheme.textSecondary)
    }
    .padding()
    .studioBackground()
}
