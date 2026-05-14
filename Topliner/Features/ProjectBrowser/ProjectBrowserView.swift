import SwiftUI

struct ProjectBrowserView: View {
    @State var viewModel = ProjectBrowserViewModel()

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: StudioLayout.panelSpacing) {
                projectToolbar

                HStack(spacing: StudioLayout.panelSpacing) {
                    projectGrid(width: proxy.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    selectedProjectPanel
                        .frame(width: min(StudioLayout.harmonyPanelWidth, max(280, proxy.size.width * 0.30)))
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(StudioLayout.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(StudioTheme.background.ignoresSafeArea())
        }
        .navigationTitle("Projects")
        .onAppear(perform: viewModel.refresh)
    }

    private var projectToolbar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Project Browser")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
                Text("Local sketches, captured takes, and MIDI sessions")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.textMuted)
            }

            Spacer(minLength: 12)

            Label("\(viewModel.filteredProjects.count) shown", systemImage: "square.grid.2x2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.textSecondary)
                .padding(.horizontal, 10)
                .frame(minHeight: StudioLayout.minimumTouchTarget)
                .background(StudioTheme.elevatedSurface.opacity(0.78), in: Capsule())

            TextField("Search title, key, or BPM", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.textPrimary)
                .padding(.horizontal, 12)
                .frame(width: 240)
                .frame(minHeight: StudioLayout.minimumTouchTarget)
                .background(StudioTheme.elevatedSurface.opacity(0.78), in: Capsule())
                .overlay(Capsule().stroke(StudioTheme.border, lineWidth: 1))

            Button {
                try? viewModel.createProject(title: "New Sketch")
            } label: {
                Label("New", systemImage: "plus")
                    .frame(minHeight: StudioLayout.minimumTouchTarget)
            }
            .buttonStyle(.borderedProminent)
            .tint(StudioTheme.cyan)

            Button {
                viewModel.refresh()
            } label: {
                Label("Import", systemImage: "tray.and.arrow.down")
                    .frame(minHeight: StudioLayout.minimumTouchTarget)
            }
            .buttonStyle(.bordered)
            .tint(StudioTheme.violet)
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

    private func projectGrid(width: CGFloat) -> some View {
        StudioPanel("Library", subtitle: "Full-screen local project grid") {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.danger)
            }

            if viewModel.filteredProjects.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let columns = width > 1040 ? 3 : 2
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    ForEach(gridRows(columns: columns), id: \.self) { row in
                        GridRow {
                            ForEach(0..<columns, id: \.self) { column in
                                let index = row * columns + column
                                if index < viewModel.filteredProjects.count {
                                    projectCard(viewModel.filteredProjects[index])
                                } else {
                                    Color.clear
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    private var selectedProjectPanel: some View {
        StudioPanel("Details", subtitle: "Selected project") {
            if let project = viewModel.selectedProject {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(StudioTheme.textPrimary)
                            .lineLimit(2)
                        Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(StudioTheme.textMuted)
                    }

                    Divider().overlay(StudioTheme.border)

                    detailMetric("Tempo", "\(Int(project.bpm)) BPM", "metronome")
                    detailMetric("Length", "\(project.totalBars) bars", "timeline.selection")
                    detailMetric("Key", project.key ?? "Unset", "music.quarternote.3")
                    detailMetric("Lead", "\(project.leadVoice.notes.count) notes", "pianokeys")
                    detailMetric("Harmony", project.chordProgression == nil ? "No chords" : "Generated", "sparkles")

                    Spacer(minLength: 8)

                    Button {
                        try? viewModel.duplicateProject(id: project.id)
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity, minHeight: StudioLayout.minimumTouchTarget)
                    }
                    .buttonStyle(.bordered)
                    .tint(StudioTheme.cyan)

                    Button(role: .destructive) {
                        try? viewModel.deleteProject(id: project.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: StudioLayout.minimumTouchTarget)
                    }
                    .buttonStyle(.bordered)
                    .tint(StudioTheme.danger)
                }
            } else {
                Text("Select or create a project to see session details.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(StudioTheme.cyan)
            Text(viewModel.searchQuery.isEmpty ? "No projects yet" : "No matching projects")
                .font(.headline.weight(.bold))
                .foregroundStyle(StudioTheme.textPrimary)
            Text("Create a sketch to save melodies, chords, captures, and MIDI settings locally.")
                .font(.caption)
                .foregroundStyle(StudioTheme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button {
                try? viewModel.createProject(title: "New Sketch")
            } label: {
                Label("Create Project", systemImage: "plus")
                    .frame(minHeight: StudioLayout.minimumTouchTarget)
            }
            .buttonStyle(.borderedProminent)
            .tint(StudioTheme.cyan)
        }
    }

    private func projectCard(_ project: ProjectDocument) -> some View {
        Button {
            viewModel.selectProject(id: project.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: project.id == viewModel.selectedProject?.id ? "folder.fill" : "folder")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(project.id == viewModel.selectedProject?.id ? StudioTheme.cyan : StudioTheme.textSecondary)
                    Spacer()
                    Text("\(Int(project.bpm))")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(StudioTheme.orange)
                }

                Text(project.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(StudioTheme.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                HStack(spacing: 8) {
                    miniPill(project.key ?? "No key")
                    miniPill("\(project.totalBars) bars")
                    miniPill("\(project.leadVoice.notes.count) notes")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(project.id == viewModel.selectedProject?.id ? StudioTheme.cyan.opacity(0.16) : StudioTheme.elevatedSurface.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(project.id == viewModel.selectedProject?.id ? StudioTheme.cyan.opacity(0.72) : StudioTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func miniPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(StudioTheme.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(StudioTheme.surface.opacity(0.82), in: Capsule())
    }

    private func detailMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(StudioTheme.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(StudioTheme.textMuted)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(StudioTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func gridRows(columns: Int) -> [Int] {
        let count = viewModel.filteredProjects.count
        guard count > 0 else { return [] }
        return Array(0..<Int(ceil(Double(count) / Double(columns))))
    }
}

#Preview {
    ProjectBrowserView()
}
