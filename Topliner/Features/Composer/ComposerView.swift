import SwiftUI

struct ComposerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            PianoRollGridView(totalBeats: 16, beatsPerBar: 4, pitchRange: 48...84)
                .frame(minHeight: 320)
        }
        .padding(20)
        .background(Color(red: 0.025, green: 0.028, blue: 0.038))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Topliner")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Draw or hum a melody, then generate harmony.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

#Preview {
    ComposerView()
}
