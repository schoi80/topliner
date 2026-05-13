struct ComposerHarmonyPanelModel: Equatable {
    struct ChordChip: Equatable, Identifiable {
        var id: Int
        var symbol: String
        var detail: String
    }

    var progression: ChordProgression?
    var isGenerating: Bool
    var variantIndex: Int

    var primaryActionTitle: String {
        if isGenerating { return "Generating…" }
        return progression == nil ? "Generate" : "Regenerate Variant"
    }

    var statusMessage: String {
        if isGenerating { return "Listening to melody context" }
        guard let progression else { return "No chords yet" }
        let count = progression.chords.count
        let noun = count == 1 ? "chord" : "chords"
        return "Variant \(variantIndex + 1) · \(count) \(noun)"
    }

    var chordChips: [ChordChip] {
        guard let progression else { return [] }
        return progression.chords.prefix(8).enumerated().map { index, chord in
            ChordChip(
                id: index,
                symbol: chord.symbol,
                detail: chord.romanNumeral ?? "beat \(formatBeat(chord.startBeat))"
            )
        }
    }

    private func formatBeat(_ beat: Double) -> String {
        if beat.rounded() == beat {
            return "\(Int(beat))"
        }
        return String(format: "%.2f", beat)
    }
}
