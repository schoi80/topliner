import Foundation

enum ChordGenerationResponseCorrectionMode: Equatable {
    case reject
    case quantizeToGrid
}

enum ChordGenerationResponseParserError: Error, Equatable {
    case missingChords
    case invalidMIDIValue(Int)
    case nonGridAlignedBeat(Double)
    case invalidConfidence(Double)
    case invalidDuration(Double)
}

struct ChordGenerationResponseParser {
    var quantizeGridBeats: Double
    var correctionMode: ChordGenerationResponseCorrectionMode

    init(
        quantizeGridBeats: Double = 0.25,
        correctionMode: ChordGenerationResponseCorrectionMode = .reject
    ) {
        self.quantizeGridBeats = quantizeGridBeats
        self.correctionMode = correctionMode
    }

    func parse(_ json: String) throws -> ChordProgression {
        let data = Data(json.utf8)
        let response = try JSONDecoder().decode(ResponseDTO.self, from: data)
        guard let chordDTOs = response.chords, !chordDTOs.isEmpty else {
            throw ChordGenerationResponseParserError.missingChords
        }

        let chords = try chordDTOs.map { try chordEvent(from: $0) }
        return ChordProgression(
            styleID: response.styleID,
            key: response.key,
            chords: chords,
            explanation: response.explanation
        )
    }

    private func chordEvent(from dto: ChordDTO) throws -> ChordEvent {
        try validateMIDI(dto.rootMidiNote)
        for midiNote in dto.midiNotes {
            try validateMIDI(midiNote)
        }

        if dto.durationBeats <= 0 {
            throw ChordGenerationResponseParserError.invalidDuration(dto.durationBeats)
        }

        if let confidence = dto.confidence, !(0...1).contains(confidence) {
            throw ChordGenerationResponseParserError.invalidConfidence(confidence)
        }

        let startBeat = try correctedBeat(dto.startBeat)
        let durationBeats = try correctedBeat(dto.durationBeats)

        return ChordEvent(
            symbol: dto.symbol,
            rootMidiNote: dto.rootMidiNote,
            midiNotes: dto.midiNotes,
            startBeat: startBeat,
            durationBeats: durationBeats,
            romanNumeral: dto.romanNumeral,
            confidence: dto.confidence
        )
    }

    private func validateMIDI(_ value: Int) throws {
        guard (0...127).contains(value) else {
            throw ChordGenerationResponseParserError.invalidMIDIValue(value)
        }
    }

    private func correctedBeat(_ value: Double) throws -> Double {
        guard quantizeGridBeats > 0 else { return value }
        let quantized = Quantizer.quantizeBeat(value, grid: quantizeGridBeats)
        if abs(quantized - value) <= 0.000_001 {
            return value
        }

        switch correctionMode {
        case .reject:
            throw ChordGenerationResponseParserError.nonGridAlignedBeat(value)
        case .quantizeToGrid:
            return quantized
        }
    }
}

private struct ResponseDTO: Decodable {
    var styleID: String
    var key: String?
    var chords: [ChordDTO]?
    var explanation: String?
}

private struct ChordDTO: Decodable {
    var symbol: String
    var rootMidiNote: Int
    var midiNotes: [Int]
    var startBeat: Double
    var durationBeats: Double
    var romanNumeral: String?
    var confidence: Double?
}
