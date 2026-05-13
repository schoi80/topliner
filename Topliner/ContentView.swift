import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ComposerView()
            }
            .tabItem {
                Label("Compose", systemImage: "pianokeys")
            }

            NavigationStack {
                AudioCaptureView()
            }
            .tabItem {
                Label("Capture", systemImage: "mic")
            }

            NavigationStack {
                ProjectBrowserView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }

            NavigationStack {
                MIDISettingsView()
            }
            .tabItem {
                Label("MIDI", systemImage: "cable.connector")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppEnvironment())
}
