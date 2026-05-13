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
        }
    }
}

#Preview {
    ContentView()
        .environment(AppEnvironment())
}
