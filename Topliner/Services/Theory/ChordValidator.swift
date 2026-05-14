import Foundation

struct ChordValidationStyleProfile: Equatable {
    var styleID: String
    var allowedQualities: [ChordQuality]

    init(styleID: String, allowedQualities: [ChordQuality]) {
        self.styleID = styleID
        self.allowedQualities = allowedQualities
    }
}

enum ChordValidationIssue: Equatable {
    case emptyProgression
    case nonGridAlignedStartBeat(chordID: UUID, value: Double)
    case nonGridAlignedDuration(chordID: UUID, value: Double)
    case invalidDuration(chordID: UUID, value: Double)
    case invalidRootMidiNote(chordID: UUID, value: Int)
    case invalidMidiNote(chordID: UUID, value: Int)
    case unparseableSymbol(chordID: UUID, symbol: String)
    case disallowedQuality(chordID: UUID, styleID: String, quality: ChordQuality)
}

struct ChordValidator {
    var quantizeGridBeats: Double
    var playableMIDIRange: ClosedRange<Int>
    var parser: ChordSymbolParser
    var styleProfiles: [ChordValidationStyleProfile]

    init(
        quantizeGridBeats: Double = 0.25,
        playableMIDIRange: ClosedRange<Int> = 0...127,
        parser: ChordSymbolParser = ChordSymbolParser(),
        styleProfiles: [ChordValidationStyleProfile] = ChordValidator.defaultStyleProfiles
    ) {
        self.quantizeGridBeats = quantizeGridBeats
        self.playableMIDIRange = playableMIDIRange
        self.parser = parser
        self.styleProfiles = styleProfiles
    }

    func isValid(_ progression: ChordProgression) -> Bool {
        validate(progression).isEmpty
    }

    func validate(_ progression: ChordProgression) -> [ChordValidationIssue] {
        guard !progression.chords.isEmpty else { return [.emptyProgression] }

        let styleProfile = styleProfiles.first { $0.styleID == progression.styleID }
        return progression.chords.flatMap { chord in
            validate(chord, styleID: progression.styleID, styleProfile: styleProfile)
        }
    }

    private func validate(
        _ chord: ChordEvent,
        styleID: String,
        styleProfile: ChordValidationStyleProfile?
    ) -> [ChordValidationIssue] {
        var issues: [ChordValidationIssue] = []

        if !isGridAligned(chord.startBeat) {
            issues.append(.nonGridAlignedStartBeat(chordID: chord.id, value: chord.startBeat))
        }

        if chord.durationBeats <= 0 {
            issues.append(.invalidDuration(chordID: chord.id, value: chord.durationBeats))
        } else if !isGridAligned(chord.durationBeats) {
            issues.append(.nonGridAlignedDuration(chordID: chord.id, value: chord.durationBeats))
        }

        if !playableMIDIRange.contains(chord.rootMidiNote) {
            issues.append(.invalidRootMidiNote(chordID: chord.id, value: chord.rootMidiNote))
        }

        for midiNote in chord.midiNotes where !playableMIDIRange.contains(midiNote) {
            issues.append(.invalidMidiNote(chordID: chord.id, value: midiNote))
        }

        do {
            let parsed = try parser.parse(chord.symbol)
            if let styleProfile, !styleProfile.allowedQualities.contains(parsed.quality) {
                issues.append(.disallowedQuality(chordID: chord.id, styleID: styleID, quality: parsed.quality))
            }
        } catch {
            issues.append(.unparseableSymbol(chordID: chord.id, symbol: chord.symbol))
        }

        return issues
    }

    private func isGridAligned(_ value: Double) -> Bool {
        guard quantizeGridBeats > 0 else { return true }
        let quantized = Quantizer.quantizeBeat(value, grid: quantizeGridBeats)
        return abs(quantized - value) <= 0.000_001
    }
}

extension ChordValidator {
    static let defaultStyleProfiles: [ChordValidationStyleProfile] = {
        let allSupported: [ChordQuality] = [
            .major,
            .minor,
            .majorSeventh,
            .minorSeventh,
            .dominantSeventh,
            .diminishedSeventh,
            .halfDiminishedSeventh,
            .majorNinth,
            .minorNinth,
            .dominantNinth,
            .dominantEleventh,
            .minorEleventh,
            .dominantThirteenth,
            .dominantThirteenthSuspended
        ]

        let triadsAndSevenths: [ChordQuality] = [
            .major,
            .minor,
            .majorSeventh,
            .minorSeventh,
            .dominantSeventh
        ]

        return [
            ChordValidationStyleProfile(styleID: "neo_soul", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "jazz", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "gospel_rnb", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "city_pop", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "bossa_nova", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "blues", allowedQualities: allSupported),
            ChordValidationStyleProfile(styleID: "funk", allowedQualities: triadsAndSevenths),
            ChordValidationStyleProfile(styleID: "synthwave", allowedQualities: triadsAndSevenths),
            ChordValidationStyleProfile(styleID: "cinematic", allowedQualities: triadsAndSevenths)
        ]
    }()
}
