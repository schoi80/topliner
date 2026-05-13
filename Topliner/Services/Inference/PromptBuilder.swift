import Foundation

struct ChordGenerationPromptBuilder {
    var quantizeGridBeats: Double

    init(quantizeGridBeats: Double = 0.25) {
        self.quantizeGridBeats = quantizeGridBeats
    }

    func buildPrompt(request: ChordGenerationRequest, style: HarmonicStyle) -> String {
        """
        You are Topliner's local chord-generation engine. Generate a musically useful chord progression that supports the supplied melody and style profile.

        Return JSON only. Do not include Markdown. Do not include prose before or after the JSON object.

        Project input:
        \(projectJSON(request: request))

        Harmonic style profile:
        \(styleJSON(style: style))

        Response schema:
        \(schemaJSON(styleID: style.id, key: request.key))

        Rules:
        - Return exactly one JSON object matching the response schema.
        - Use the requested styleID and key exactly as supplied.
        - Generate chords that support the melodyNotes rhythm and pitch contour.
        - Match requested complexity: simple = fewer/basic chords, balanced = style seed density, advanced = richer extensions/color with passing chords, turnaround chords, secondary dominants, and neighbor chords as harmonic glue.
        - If previousProgression is present, this is a regeneration request. Generate a meaningfully different variant: do not repeat the same chord symbols, roman numerals, or harmonic rhythm unless required by the melody.
        - All startBeat and durationBeats values must align to \(formatNumber(quantizeGridBeats))-beat grid.
        - Chord events must cover useful portions of the requested totalBeats without negative starts or durations.
        - MIDI values must be integers in the 0...127 range.
        - confidence must be between 0.0 and 1.0.
        - romanNumeral may be null if unavailable, but symbol/rootMidiNote/midiNotes must still be populated.
        """
    }

    private func projectJSON(request: ChordGenerationRequest) -> String {
        let notes = request.melodyNotes
            .sorted { lhs, rhs in
                if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
                return lhs.startBeat < rhs.startBeat
            }
            .map { note in
                """
                    {
                      "pitch": \(note.pitch),
                      "startBeat": \(formatNumber(note.startBeat)),
                      "durationBeats": \(formatNumber(note.durationBeats)),
                      "velocity": \(note.velocity)
                    }
                """
            }
            .joined(separator: ",\n")

        return """
        {
          "styleID": "\(escaped(request.styleID))",
          "key": "\(escaped(request.key))",
          "bpm": \(formatNumber(request.bpm)),
          "totalBeats": \(formatNumber(request.totalBeats)),
          "complexity": "\(request.complexity.rawValue)",
          "variantIndex": \(request.variantIndex),
          "previousProgression": \(previousProgressionJSON(request.previousProgression)),
          "melodyNotes": [
        \(notes)
          ]
        }
        """
    }

    private func previousProgressionJSON(_ progression: ChordProgression?) -> String {
        guard let progression else { return "null" }
        let chords = progression.chords.map { chord in
            """
                {
                  "symbol": "\(escaped(chord.symbol))",
                  "rootMidiNote": \(chord.rootMidiNote),
                  "midiNotes": [\(chord.midiNotes.map(String.init).joined(separator: ", "))],
                  "startBeat": \(formatNumber(chord.startBeat)),
                  "durationBeats": \(formatNumber(chord.durationBeats)),
                  "romanNumeral": \(optionalStringJSON(chord.romanNumeral))
                }
            """
        }.joined(separator: ",\n")
        return """
        {
          "styleID": "\(escaped(progression.styleID))",
          "key": "\(escaped(progression.key ?? ""))",
          "chords": [
        \(chords)
          ]
        }
        """
    }

    private func optionalStringJSON(_ value: String?) -> String {
        guard let value else { return "null" }
        return "\"\(escaped(value))\""
    }

    private func styleJSON(style: HarmonicStyle) -> String {
        let seeds = style.progressionSeeds.map { seed in
            let chords = seed.chords.map { "\"\(escaped($0))\"" }.joined(separator: ", ")
            return """
                {
                  "name": "\(escaped(seed.name))",
                  "chords": [\(chords)]
                }
            """
        }
        .joined(separator: ",\n")

        return """
        {
          "id": "\(escaped(style.id))",
          "displayName": "\(escaped(style.displayName))",
          "promptInstructions": "\(escaped(style.promptInstructions))",
          "progressionSeeds": [
        \(seeds)
          ]
        }
        """
    }

    private func schemaJSON(styleID: String, key: String) -> String {
        """
        {
          "styleID": "\(escaped(styleID))",
          "key": "\(escaped(key))",
          "chords": [
            {
              "symbol": "Cmaj9",
              "rootMidiNote": 60,
              "midiNotes": [60, 64, 67, 71, 74],
              "startBeat": 0,
              "durationBeats": 1,
              "romanNumeral": "Imaj9",
              "confidence": 0.95
            }
          ],
          "explanation": "Brief reason for harmonic choices."
        }
        """
    }

    private func formatNumber(_ value: Double) -> String {
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    private func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
