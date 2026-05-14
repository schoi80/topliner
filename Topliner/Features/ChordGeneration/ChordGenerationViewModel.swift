import Foundation
import Observation

enum ChordGenerationComplexity: String, CaseIterable, Identifiable, Equatable {
    case simple
    case balanced
    case advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .balanced: return "Balanced"
        case .advanced: return "Advanced"
        }
    }
}

@Observable
final class ChordGenerationViewModel {
    var selectedStyleID: String
    var selectedComplexity: ChordGenerationComplexity
    var isGenerating: Bool = false
    var generatedProgression: ChordProgression?
    var errorMessage: String?
    private(set) var generationCount: Int = 0

    private(set) var styleLibrary: StyleLibrary
    private var provider: any ChordGenerationProviding

    init(
        styleLibrary: StyleLibrary,
        provider: any ChordGenerationProviding,
        selectedStyleID: String? = nil,
        selectedComplexity: ChordGenerationComplexity = .balanced
    ) {
        self.styleLibrary = styleLibrary
        self.provider = provider
        self.selectedStyleID = selectedStyleID ?? styleLibrary.styles.first?.id ?? ""
        self.selectedComplexity = selectedComplexity
    }

    convenience init() {
        let library = (try? StyleLibrary.defaultLibrary()) ?? StyleLibrary(styles: [])
        self.init(styleLibrary: library, provider: MockChordGenerationProvider(styleLibrary: library))
    }

    var availableStyles: [HarmonicStyle] {
        styleLibrary.styles
    }

    var selectedStyle: HarmonicStyle? {
        styleLibrary.style(id: selectedStyleID)
    }

    var chordLaneSummary: String? {
        guard let progression = generatedProgression, !progression.chords.isEmpty else { return nil }
        return progression.chords.map(\.symbol).joined(separator: " · ")
    }

    var generatedChordNotes: [MIDINoteEvent] {
        generatedProgression?.chords.flatMap { chord in
            chord.midiNotes.map { pitch in
                MIDINoteEvent(
                    pitch: pitch,
                    startBeat: chord.startBeat,
                    durationBeats: chord.durationBeats,
                    velocity: 82
                )
            }
        } ?? []
    }

    func generateChords(
        melodyNotes: [MIDINoteEvent],
        key: String,
        bpm: Double,
        totalBeats: Double
    ) {
        isGenerating = true
        errorMessage = nil
        let previousProgression = generatedProgression
        generatedProgression = nil

        let request = ChordGenerationRequest(
            styleID: selectedStyleID,
            key: key,
            bpm: bpm,
            melodyNotes: melodyNotes,
            totalBeats: totalBeats,
            complexity: selectedComplexity,
            previousProgression: previousProgression,
            variantIndex: generationCount
        )

        do {
            generatedProgression = try provider.generateProgression(for: request)
            generationCount += 1
        } catch {
            errorMessage = friendlyMessage(for: error)
        }

        isGenerating = false
    }

    func clearGeneratedChords() {
        generatedProgression = nil
        errorMessage = nil
        generationCount = 0
    }

    private func friendlyMessage(for error: Error) -> String {
        if let generationError = error as? ChordGenerationError {
            switch generationError {
            case .unknownStyle(let styleID):
                return "Unknown style: \(styleID)"
            case .emptyProgressionSeed(let styleID):
                return "No progression seeds for style: \(styleID)"
            case .invalidTotalBeats(let totalBeats):
                return "Invalid progression length: \(totalBeats) beats"
            }
        }
        return error.localizedDescription
    }
}
