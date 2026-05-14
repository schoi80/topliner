import Foundation

struct ParsedChordSymbol: Equatable {
    var symbol: String
    var rootName: String
    var rootPitchClass: Int
    var quality: ChordQuality
    var intervals: [Int] { quality.intervals }

    func midiNotes(rootMidiNote: Int) -> [Int] {
        intervals.map { rootMidiNote + $0 }
    }
}

enum ChordQuality: Equatable {
    case major
    case minor
    case majorSeventh
    case minorSeventh
    case dominantSeventh
    case diminishedSeventh
    case halfDiminishedSeventh
    case majorNinth
    case minorNinth
    case dominantNinth
    case dominantEleventh
    case minorEleventh
    case dominantThirteenth
    case dominantThirteenthSuspended

    var intervals: [Int] {
        switch self {
        case .major:
            return [0, 4, 7]
        case .minor:
            return [0, 3, 7]
        case .majorSeventh:
            return [0, 4, 7, 11]
        case .minorSeventh:
            return [0, 3, 7, 10]
        case .dominantSeventh:
            return [0, 4, 7, 10]
        case .diminishedSeventh:
            return [0, 3, 6, 9]
        case .halfDiminishedSeventh:
            return [0, 3, 6, 10]
        case .majorNinth:
            return [0, 4, 7, 11, 14]
        case .minorNinth:
            return [0, 3, 7, 10, 14]
        case .dominantNinth:
            return [0, 4, 7, 10, 14]
        case .dominantEleventh:
            return [0, 4, 7, 10, 14, 17]
        case .minorEleventh:
            return [0, 3, 7, 10, 14, 17]
        case .dominantThirteenth:
            return [0, 4, 7, 10, 14, 17, 21]
        case .dominantThirteenthSuspended:
            return [0, 5, 7, 10, 14, 21]
        }
    }
}

enum ChordSymbolParserError: Error, Equatable {
    case emptySymbol
    case invalidRoot(String)
    case unsupportedQuality(String)
}

struct ChordSymbolParser {
    func parse(_ symbol: String) throws -> ParsedChordSymbol {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ChordSymbolParserError.emptySymbol }

        let root = try parseRoot(in: trimmed)
        let suffixStart = trimmed.index(trimmed.startIndex, offsetBy: root.characterCount)
        let suffix = String(trimmed[suffixStart...])
        let quality = try parseQuality(suffix)

        return ParsedChordSymbol(
            symbol: trimmed,
            rootName: root.name,
            rootPitchClass: root.pitchClass,
            quality: quality
        )
    }

    private func parseRoot(in symbol: String) throws -> (name: String, pitchClass: Int, characterCount: Int) {
        guard let first = symbol.first else { throw ChordSymbolParserError.emptySymbol }
        guard "ABCDEFG".contains(first) else {
            throw ChordSymbolParserError.invalidRoot(String(first))
        }

        var rootName = String(first)
        var characterCount = 1
        let secondIndex = symbol.index(after: symbol.startIndex)
        if secondIndex < symbol.endIndex {
            let second = symbol[secondIndex]
            if second == "#" || second == "b" {
                rootName.append(second)
                characterCount += 1
            }
        }

        guard let pitchClass = NotePitchClass.pitchClass(for: rootName) else {
            throw ChordSymbolParserError.invalidRoot(rootName)
        }

        return (rootName, pitchClass, characterCount)
    }

    private func parseQuality(_ suffix: String) throws -> ChordQuality {
        switch suffix {
        case "": return .major
        case "m": return .minor
        case "maj7": return .majorSeventh
        case "m7": return .minorSeventh
        case "7": return .dominantSeventh
        case "dim7": return .diminishedSeventh
        case "ø7": return .halfDiminishedSeventh
        case "maj9": return .majorNinth
        case "m9": return .minorNinth
        case "9": return .dominantNinth
        case "11": return .dominantEleventh
        case "m11": return .minorEleventh
        case "13": return .dominantThirteenth
        case "13sus": return .dominantThirteenthSuspended
        default: throw ChordSymbolParserError.unsupportedQuality(suffix)
        }
    }
}

private enum NotePitchClass {
    private static let values: [String: Int] = [
        "C": 0,
        "C#": 1,
        "Db": 1,
        "D": 2,
        "D#": 3,
        "Eb": 3,
        "E": 4,
        "F": 5,
        "F#": 6,
        "Gb": 6,
        "G": 7,
        "G#": 8,
        "Ab": 8,
        "A": 9,
        "A#": 10,
        "Bb": 10,
        "B": 11
    ]

    static func pitchClass(for rootName: String) -> Int? {
        values[rootName]
    }
}
