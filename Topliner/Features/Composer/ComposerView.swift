import SwiftUI

struct ComposerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            PianoRollView(notes: sampleNotes, selectedNoteID: sampleNotes.first?.id)
                .frame(minHeight: 320)
        }
        .padding(20)
        .background(Color(red: 0.025, green: 0.028, blue: 0.038))
    }

    private var sampleNotes: [MIDINoteEvent] {
        [
            MIDINoteEvent(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 62, startBeat: 1, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 64, startBeat: 2, durationBeats: 1, velocity: 100),
            MIDINoteEvent(pitch: 67, startBeat: 3, durationBeats: 2, velocity: 100),
            MIDINoteEvent(pitch: 69, startBeat: 6, durationBeats: 1.5, velocity: 100)
        ]
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
