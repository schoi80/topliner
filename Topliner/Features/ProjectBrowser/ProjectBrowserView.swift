import SwiftUI

struct ProjectBrowserView: View {
    @State var viewModel = ProjectBrowserViewModel()

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            if viewModel.projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "music.note.list",
                    description: Text("Create a sketch to save melodies, chords, and MIDI settings locally.")
                )
            } else {
                ForEach(viewModel.projects) { project in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.headline)
                        Text("\(project.bpm, specifier: "%.0f") BPM · \(project.totalBars) bars")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            try? viewModel.deleteProject(id: project.id)
                        }
                        Button("Duplicate") {
                            try? viewModel.duplicateProject(id: project.id)
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            Button {
                try? viewModel.createProject(title: "New Sketch")
            } label: {
                Label("New Project", systemImage: "plus")
            }
        }
        .onAppear(perform: viewModel.refresh)
    }
}

#Preview {
    NavigationStack {
        ProjectBrowserView()
    }
}
