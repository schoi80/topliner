enum Quantizer {
    static func quantizeBeat(_ beat: Double, grid: Double) -> Double {
        guard grid > 0 else { return beat }
        return (beat / grid).rounded() * grid
    }

    static func quantize(note: MIDINoteEvent, grid: Double, minimumDuration: Double) -> MIDINoteEvent {
        var copy = note
        copy.startBeat = quantizeBeat(note.startBeat, grid: grid)
        copy.durationBeats = max(minimumDuration, quantizeBeat(note.durationBeats, grid: grid))
        return copy
    }
}
