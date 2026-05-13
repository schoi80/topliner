import SwiftUI

struct StudioTheme {
    static let background = Color(red: 0.025, green: 0.028, blue: 0.038)
    static let surface = Color(red: 0.055, green: 0.063, blue: 0.086)
    static let elevatedSurface = Color(red: 0.075, green: 0.085, blue: 0.112)
    static let panel = Color(red: 0.043, green: 0.050, blue: 0.070)
    static let border = Color.white.opacity(0.10)
    static let grid = Color.white.opacity(0.07)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.64)
    static let textMuted = Color.white.opacity(0.42)
    static let cyan = Color(red: 0.12, green: 0.86, blue: 0.95)
    static let violet = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let orange = Color(red: 0.98, green: 0.45, blue: 0.18)
    static let lime = Color(red: 0.68, green: 0.94, blue: 0.20)
    static let danger = Color(red: 0.96, green: 0.25, blue: 0.34)
}

enum StudioLayout {
    static let screenPadding: CGFloat = 14
    static let panelSpacing: CGFloat = 12
    static let panelCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12
    static let minimumTransportHeight: CGFloat = 58
    static let minimumToolbarHeight: CGFloat = 58
    static let minimumTouchTarget: CGFloat = 44
    static let pitchStripWidth: CGFloat = 58
    static let harmonyPanelWidth: CGFloat = 286
}

struct StudioTransportState: Equatable {
    var projectTitle: String
    var bpm: Double
    var barLength: Int
    var isMetronomeEnabled: Bool
    var snapLabel: String

    var clampedBPM: Int {
        min(max(Int(bpm.rounded()), 40), 240)
    }

    var clampedBarLength: Int {
        min(max(barLength, 1), 16)
    }

    var bpmLabel: String {
        "\(clampedBPM) BPM"
    }

    var barLengthLabel: String {
        "\(clampedBarLength) bars"
    }

    var loopLengthLabel: String {
        "\(clampedBarLength * 4) beats"
    }

    var metronomeLabel: String {
        isMetronomeEnabled ? "Metro On" : "Metro Off"
    }

    var snapDisplayLabel: String {
        "Snap \(snapLabel)"
    }
}

extension View {
    func studioBackground() -> some View {
        background(
            LinearGradient(
                colors: [
                    StudioTheme.background,
                    Color(red: 0.020, green: 0.025, blue: 0.040),
                    Color(red: 0.038, green: 0.032, blue: 0.060)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
