import Foundation

struct MockChordGenerationProvider: ChordGenerationProviding {
    var styleLibrary: StyleLibrary

    init(styleLibrary: StyleLibrary) {
        self.styleLibrary = styleLibrary
    }

    func generateProgression(for request: ChordGenerationRequest) throws -> ChordProgression {
        guard request.totalBeats > 0 else { throw ChordGenerationError.invalidTotalBeats(request.totalBeats) }
        guard let style = styleLibrary.style(id: request.styleID) else {
            throw ChordGenerationError.unknownStyle(request.styleID)
        }
        guard style.progressionSeeds.contains(where: { !$0.chords.isEmpty }) else {
            throw ChordGenerationError.emptyProgressionSeed(style.id)
        }
        let seed = selectedSeed(for: request, style: style)
        let romanChords = chords(from: seed, complexity: request.complexity)
        let duration = request.totalBeats / Double(romanChords.count)
        let events = romanChords.enumerated().map { index, romanChord in
            let resolvedChord = ResolvedChord(romanChord: romanChord, key: request.key)
            return ChordEvent(
                symbol: resolvedChord.symbol,
                rootMidiNote: resolvedChord.rootMidiNote,
                midiNotes: resolvedChord.midiNotes,
                startBeat: Double(index) * duration,
                durationBeats: duration,
                romanNumeral: romanChord,
                confidence: 1.0
            )
        }

        return ChordProgression(
            styleID: style.id,
            key: request.key,
            chords: events,
            explanation: "Mock progression variant \(request.variantIndex + 1) (\(request.complexity.displayName.lowercased())) using \(style.displayName) seed \"\(seed.name)\" and \(request.melodyNotes.count) melody note(s)."
        )
    }

    private func selectedSeed(for request: ChordGenerationRequest, style: HarmonicStyle) -> ProgressionSeed {
        let nonEmptySeeds = style.progressionSeeds.filter { !$0.chords.isEmpty }
        guard !nonEmptySeeds.isEmpty else {
            return ProgressionSeed(name: "Fallback", chords: ["I", "IV", "V", "I"])
        }
        guard nonEmptySeeds.count > 1, let firstNote = request.melodyNotes.sorted(by: melodySort).first else {
            let variantOffset = max(0, request.variantIndex)
            return nonEmptySeeds[variantOffset % nonEmptySeeds.count]
        }

        let melodyBucket = melodicSeedBucket(for: firstNote.pitch)
        let variantOffset = max(0, request.variantIndex)
        let previousRomans = request.previousProgression?.chords.compactMap(\.romanNumeral) ?? []
        let preferredIndex = (melodyBucket + variantOffset) % nonEmptySeeds.count
        let preferredSeed = nonEmptySeeds[preferredIndex]
        if !previousRomans.isEmpty, previousRomans == chords(from: preferredSeed, complexity: request.complexity) {
            return nonEmptySeeds[(preferredIndex + 1) % nonEmptySeeds.count]
        }
        return preferredSeed
    }

    private func melodySort(_ lhs: MIDINoteEvent, _ rhs: MIDINoteEvent) -> Bool {
        if lhs.startBeat == rhs.startBeat { return lhs.pitch < rhs.pitch }
        return lhs.startBeat < rhs.startBeat
    }

    private func melodicSeedBucket(for pitch: Int) -> Int {
        let pitchClass = (pitch % 12 + 12) % 12
        switch pitchClass {
        case 0, 2, 4, 5, 7: return 0
        default: return 1
        }
    }

    private func chords(from seed: ProgressionSeed, complexity: ChordGenerationComplexity) -> [String] {
        switch complexity {
        case .simple:
            return Array(seed.chords.prefix(max(1, min(2, seed.chords.count)))).map(simplified)
        case .balanced:
            return seed.chords
        case .advanced:
            return advancedChords(from: seed.chords)
        }
    }

    private func advancedChords(from baseChords: [String]) -> [String] {
        guard !baseChords.isEmpty else { return [] }
        var advanced: [String] = []
        let glue = ["#ivø7", "V7/vi", "bII7", "viiø7"]
        for (index, chord) in baseChords.enumerated() {
            advanced.append(enriched(chord))
            advanced.append(glue[index % glue.count])
        }
        return advanced
    }

    private func simplified(_ romanChord: String) -> String {
        let parsed = RomanChordParser.parse(romanChord)
        return parsed.originalPrefix + simplifiedSuffix(for: parsed)
    }

    private func simplifiedSuffix(for parsed: ParsedRomanChord) -> String {
        if parsed.symbolSuffix.hasPrefix("m") { return "m" }
        if parsed.symbolSuffix.contains("sus") { return "sus" }
        if parsed.symbolSuffix.contains("7") { return "7" }
        return ""
    }

    private func enriched(_ romanChord: String) -> String {
        let parsed = RomanChordParser.parse(romanChord)
        if parsed.symbolSuffix.contains("alt") { return parsed.originalPrefix + "7alt" }
        if parsed.symbolSuffix.contains("13") { return parsed.originalPrefix + "13" }
        if parsed.symbolSuffix.contains("9") { return parsed.originalPrefix + parsed.symbolSuffix }
        if parsed.symbolSuffix.contains("maj") { return parsed.originalPrefix + "maj9" }
        if parsed.symbolSuffix.hasPrefix("m") { return parsed.originalPrefix + "m9" }
        if parsed.symbolSuffix.contains("sus") { return parsed.originalPrefix + "13sus" }
        if parsed.symbolSuffix.contains("7") { return parsed.originalPrefix + "9" }
        return parsed.originalPrefix + (parsed.originalPrefix.first?.isLowercase == true ? "m9" : "add9")
    }
}

private struct ResolvedChord {
    var symbol: String
    var rootMidiNote: Int
    var midiNotes: [Int]

    init(romanChord: String, key: String) {
        let keyRoot = KeyRoot(key)
        let parsed = RomanChordParser.parse(romanChord)
        let rootPitchClass = (keyRoot.pitchClass + parsed.offsetSemitones + 120) % 12
        let rootName = NoteName.spell(pitchClass: rootPitchClass, preferFlats: keyRoot.preferFlats)
        let qualitySuffix = parsed.symbolSuffix

        self.symbol = rootName + qualitySuffix
        self.rootMidiNote = 60 + rootPitchClass
        self.midiNotes = ChordVoicing.notes(rootMidiNote: rootMidiNote, qualitySuffix: qualitySuffix)
    }
}

private struct ParsedRomanChord {
    var offsetSemitones: Int
    var symbolSuffix: String
    var originalPrefix: String
}

private enum RomanChordParser {
    static func parse(_ romanChord: String) -> ParsedRomanChord {
        let accidental = accidentalPrefix(in: romanChord)
        let withoutAccidental = String(romanChord.dropFirst(accidental.characterCount))
        let numeral = numeralPrefix(in: withoutAccidental)
        let suffixStart = withoutAccidental.index(withoutAccidental.startIndex, offsetBy: numeral.count)
        let rawSuffix = String(withoutAccidental[suffixStart...])
        let offset = interval(for: numeral) + accidental.semitones
        return ParsedRomanChord(
            offsetSemitones: offset,
            symbolSuffix: suffix(forNumeral: numeral, rawSuffix: rawSuffix),
            originalPrefix: String(romanChord.prefix(accidental.characterCount + numeral.count))
        )
    }

    private static func accidentalPrefix(in value: String) -> (semitones: Int, characterCount: Int) {
        if value.hasPrefix("bb") { return (-2, 2) }
        if value.hasPrefix("b") { return (-1, 1) }
        if value.hasPrefix("##") { return (2, 2) }
        if value.hasPrefix("#") { return (1, 1) }
        return (0, 0)
    }

    private static func numeralPrefix(in value: String) -> String {
        var prefix = ""
        for character in value {
            guard "ivIV".contains(character) else { break }
            prefix.append(character)
        }
        return prefix.isEmpty ? value : prefix
    }

    private static func interval(for numeral: String) -> Int {
        switch numeral.lowercased() {
        case "i": return 0
        case "ii": return 2
        case "iii": return 4
        case "iv": return 5
        case "v": return 7
        case "vi": return 9
        case "vii": return 11
        default: return 0
        }
    }

    private static func suffix(forNumeral numeral: String, rawSuffix: String) -> String {
        if rawSuffix.isEmpty {
            return numeral.first?.isLowercase == true ? "m" : ""
        }

        if rawSuffix.hasPrefix("ø") {
            let remainder = rawSuffix.dropFirst()
            return remainder == "7" ? "m7b5" : "m7b5" + remainder
        }

        if numeral.first?.isLowercase == true, rawSuffix.first?.isNumber == true {
            return "m" + rawSuffix
        }

        return rawSuffix
    }
}

private struct KeyRoot {
    var pitchClass: Int
    var preferFlats: Bool

    init(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let root = trimmed.replacingOccurrences(of: " minor", with: "").replacingOccurrences(of: " major", with: "")
        self.pitchClass = NoteName.pitchClass(for: root)
        self.preferFlats = root.contains("b") || ["F", "Bb", "Eb", "Ab", "Db", "Gb", "Cb"].contains(root)
    }
}

private enum NoteName {
    private static let sharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private static let flatNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

    static func pitchClass(for noteName: String) -> Int {
        let normalized = noteName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = sharpNames.firstIndex(of: normalized) { return index }
        if let index = flatNames.firstIndex(of: normalized) { return index }
        return 0
    }

    static func spell(pitchClass: Int, preferFlats: Bool) -> String {
        let names = preferFlats ? flatNames : sharpNames
        return names[(pitchClass + 120) % 12]
    }
}

private enum ChordVoicing {
    static func notes(rootMidiNote: Int, qualitySuffix: String) -> [Int] {
        let intervals: [Int]
        if qualitySuffix.hasPrefix("m7b5") {
            intervals = [0, 3, 6, 10]
        } else if qualitySuffix.hasPrefix("m") {
            intervals = qualitySuffix.contains("9") ? [0, 3, 7, 10, 14] : [0, 3, 7]
        } else if qualitySuffix.contains("maj9") {
            intervals = [0, 4, 7, 11, 14]
        } else if qualitySuffix.contains("maj7") {
            intervals = [0, 4, 7, 11]
        } else if qualitySuffix.contains("13") {
            intervals = [0, 4, 7, 10, 21]
        } else if qualitySuffix.contains("9") {
            intervals = [0, 4, 7, 10, 14]
        } else if qualitySuffix.contains("7") {
            intervals = [0, 4, 7, 10]
        } else if qualitySuffix.contains("6") {
            intervals = [0, 4, 7, 9]
        } else if qualitySuffix.contains("sus") {
            intervals = [0, 5, 7]
        } else {
            intervals = [0, 4, 7]
        }
        return intervals.map { rootMidiNote + $0 }
    }
}
