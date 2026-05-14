import SwiftUI

struct ToplinerAppShell: View {
    @State private var selectedSection: ToplinerSection = .compose

    var body: some View {
        VStack(spacing: 0) {
            topNavigation

            activeScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .all)
        .persistentSystemOverlays(.hidden)
        .statusBarHidden(true)
    }

    private var topNavigation: some View {
        HStack(spacing: 12) {
            Text("TOPLINER")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(StudioTheme.violet)
                .frame(width: 112, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(ToplinerSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        StudioControlChip(
                            title: section.title,
                            value: nil,
                            systemImage: section.systemImage,
                            isActive: selectedSection == section,
                            tint: section == .midi ? StudioTheme.orange : StudioTheme.cyan
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, StudioLayout.screenPadding)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(StudioTheme.background.opacity(0.98))
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch selectedSection {
        case .compose:
            ComposerView()
        case .capture:
            NavigationStack { AudioCaptureView() }
        case .projects:
            NavigationStack { ProjectBrowserView() }
        case .midi:
            MIDISettingsView()
        }
    }
}

#Preview {
    ToplinerAppShell()
        .environment(AppEnvironment())
}
