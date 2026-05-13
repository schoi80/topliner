import Foundation

enum ChordVoicingStyle: Equatable {
    case close
    case open
    case dropTwo
}

struct ChordVoicer {
    var range: ClosedRange<Int>
    var parser: ChordSymbolParser

    init(range: ClosedRange<Int> = 48...72, parser: ChordSymbolParser = ChordSymbolParser()) {
        self.range = range
        self.parser = parser
    }

    func voice(
        symbol: String,
        previousVoicing: [Int] = [],
        includeBassRoot: Bool = false,
        style: ChordVoicingStyle = .close
    ) throws -> [Int] {
        let chord = try parser.parse(symbol)
        let body: [Int]
        switch style {
        case .close:
            body = closeVoicing(for: chord, previousVoicing: previousVoicing)
        case .open:
            body = openVoicing(for: chord)
        case .dropTwo:
            body = dropTwoLikeVoicing(for: chord)
        }

        guard includeBassRoot else { return body }
        return [bassRoot(for: chord, below: body.first ?? range.lowerBound)] + body
    }

    private func closeVoicing(for chord: ParsedChordSymbol, previousVoicing: [Int]) -> [Int] {
        let tones = chordTones(for: chord)
        let candidates = closeCandidates(rootPitchClass: chord.rootPitchClass, tonePitchClasses: tones)
        guard !candidates.isEmpty else { return [] }

        if previousVoicing.isEmpty {
            return candidates.min { lhs, rhs in
                let lhsScore = defaultCloseScore(lhs, rootPitchClass: chord.rootPitchClass)
                let rhsScore = defaultCloseScore(rhs, rootPitchClass: chord.rootPitchClass)
                return lhsScore < rhsScore
            } ?? []
        }

        return candidates.min { lhs, rhs in
            let lhsScore = voiceLeadingScore(lhs, previousVoicing: previousVoicing)
            let rhsScore = voiceLeadingScore(rhs, previousVoicing: previousVoicing)
            return lhsScore < rhsScore
        } ?? []
    }

    private func openVoicing(for chord: ParsedChordSymbol) -> [Int] {
        let tones = chordTones(for: chord)
        guard !tones.isEmpty else { return [] }
        let root = lowestNote(in: range, pitchClass: chord.rootPitchClass) ?? range.lowerBound
        var notes: [Int] = [root]

        if tones.count >= 3 {
            notes.append(nextNote(pitchClass: tones[2], after: root + 1))
            notes.append(nextNote(pitchClass: tones[1], after: notes.last! + 1))
        }
        if tones.count >= 4 {
            notes.append(nextNote(pitchClass: tones[3], after: notes.last! + 1))
        }

        return fitIntoRange(notes)
    }

    private func dropTwoLikeVoicing(for chord: ParsedChordSymbol) -> [Int] {
        let tones = chordTones(for: chord)
        guard !tones.isEmpty else { return [] }
        let root = lowestNote(in: range, pitchClass: chord.rootPitchClass) ?? range.lowerBound
        var notes: [Int] = [root]

        if tones.count >= 3 {
            notes.append(nextNote(pitchClass: tones[2], after: root + 1))
        }
        if tones.count >= 4 {
            notes.append(nextNote(pitchClass: tones[3], after: notes.last! + 1))
        }
        if tones.count >= 2 {
            notes.append(nextNote(pitchClass: tones[1], after: notes.last! + 1))
        }

        return fitIntoRange(notes)
    }

    private func chordTones(for chord: ParsedChordSymbol) -> [Int] {
        let intervals = Array(chord.intervals.prefix(chord.intervals.count >= 4 ? 4 : chord.intervals.count))
        return intervals.map { (chord.rootPitchClass + $0) % 12 }
    }

    private func closeCandidates(rootPitchClass: Int, tonePitchClasses: [Int]) -> [[Int]] {
        let notesByPitchClass = tonePitchClasses.map { pitchClass in
            notes(in: range, pitchClass: pitchClass)
        }
        guard notesByPitchClass.allSatisfy({ !$0.isEmpty }) else { return [] }

        var candidates: Set<[Int]> = []
        buildCandidates(notesByPitchClass, index: 0, current: [], output: &candidates)
        return candidates
            .filter { $0.count == tonePitchClasses.count }
            .filter { $0.last! - $0.first! <= 12 }
            .sorted { lhs, rhs in
                if lhs.first == rhs.first { return lhs.lexicographicallyPrecedes(rhs) }
                return lhs.first! < rhs.first!
            }
    }

    private func buildCandidates(
        _ choices: [[Int]],
        index: Int,
        current: [Int],
        output: inout Set<[Int]>
    ) {
        if index == choices.count {
            let sorted = current.sorted()
            if Set(sorted).count == sorted.count {
                output.insert(sorted)
            }
            return
        }

        for note in choices[index] {
            buildCandidates(choices, index: index + 1, current: current + [note], output: &output)
        }
    }

    private func defaultCloseScore(_ notes: [Int], rootPitchClass: Int) -> Int {
        let rootPenalty = notes.first.map { pitchClass($0) == rootPitchClass ? 0 : 1_000 } ?? 1_000
        return rootPenalty + abs((notes.first ?? range.lowerBound) - range.lowerBound) + ((notes.last ?? range.lowerBound) - (notes.first ?? range.lowerBound))
    }

    private func voiceLeadingScore(_ notes: [Int], previousVoicing: [Int]) -> Int {
        let movement = zip(previousVoicing, notes).reduce(0) { total, pair in
            total + abs(pair.0 - pair.1)
        }
        let commonToneBonus = Set(previousVoicing).intersection(Set(notes)).count * 2
        let span = (notes.last ?? 0) - (notes.first ?? 0)
        return (movement * 10) + span - commonToneBonus
    }

    private func notes(in range: ClosedRange<Int>, pitchClass: Int) -> [Int] {
        range.filter { self.pitchClass($0) == pitchClass }
    }

    private func lowestNote(in range: ClosedRange<Int>, pitchClass: Int) -> Int? {
        notes(in: range, pitchClass: pitchClass).first
    }

    private func nextNote(pitchClass: Int, after minimum: Int) -> Int {
        var candidate = minimum
        while self.pitchClass(candidate) != pitchClass {
            candidate += 1
        }
        return candidate
    }

    private func fitIntoRange(_ notes: [Int]) -> [Int] {
        var fitted = notes
        while let last = fitted.last, last > range.upperBound {
            fitted = fitted.map { $0 - 12 }
        }
        while let first = fitted.first, first < range.lowerBound {
            fitted = fitted.map { $0 + 12 }
        }
        return fitted
    }

    private func bassRoot(for chord: ParsedChordSymbol, below firstBodyNote: Int) -> Int {
        var candidate = firstBodyNote - 12
        while pitchClass(candidate) != chord.rootPitchClass {
            candidate -= 1
        }
        return candidate
    }

    private func pitchClass(_ midiNote: Int) -> Int {
        (midiNote % 12 + 12) % 12
    }
}
