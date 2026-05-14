import Foundation
import Observation

#if os(iOS)
import QuartzCore
#endif

@Observable
final class PlayheadController {
    var currentBeat: Double
    var isPlaying: Bool
    var bpm: Double
    var totalBeats: Double

    #if os(iOS)
    @ObservationIgnored private var displayLink: CADisplayLink?
    @ObservationIgnored private var lastTimestamp: CFTimeInterval?
    #endif

    init(currentBeat: Double = 0, isPlaying: Bool = false, bpm: Double, totalBeats: Double) {
        self.currentBeat = currentBeat
        self.isPlaying = isPlaying
        self.bpm = bpm
        self.totalBeats = totalBeats
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        startDisplayLinkIfAvailable()
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        stopDisplayLinkIfAvailable()
    }

    func reset() {
        stop()
        currentBeat = 0
    }

    func advance(elapsedSeconds: Double) {
        guard isPlaying, elapsedSeconds > 0, bpm > 0 else { return }

        let beatsPerSecond = bpm / 60
        let nextBeat = currentBeat + elapsedSeconds * beatsPerSecond
        currentBeat = wrappedBeat(nextBeat)
    }

    private func wrappedBeat(_ beat: Double) -> Double {
        guard totalBeats > 0 else { return 0 }
        let wrapped = beat.truncatingRemainder(dividingBy: totalBeats)
        return wrapped >= 0 ? wrapped : wrapped + totalBeats
    }

    private func startDisplayLinkIfAvailable() {
        #if os(iOS)
        lastTimestamp = nil
        displayLink?.invalidate()
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        #endif
    }

    private func stopDisplayLinkIfAvailable() {
        #if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
        #endif
    }

    #if os(iOS)
    @objc private func displayLinkDidTick(_ displayLink: CADisplayLink) {
        defer { lastTimestamp = displayLink.timestamp }
        guard let lastTimestamp else { return }
        advance(elapsedSeconds: displayLink.timestamp - lastTimestamp)
    }
    #endif
}
