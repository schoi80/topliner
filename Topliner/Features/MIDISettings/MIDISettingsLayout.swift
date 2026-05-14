import SwiftUI

enum MIDISettingsPanelKind: Equatable {
    case routing
    case bluetooth
    case network
}

struct MIDISettingsContentColumn: Equatable {
    var panel: MIDISettingsPanelKind
    var width: CGFloat
}

struct MIDISettingsLandscapeLayout: Equatable {
    var availableWidth: CGFloat
    var availableHeight: CGFloat

    var horizontalPadding: CGFloat { StudioLayout.screenPadding }
    var verticalSpacing: CGFloat { 10 }
    var panelSpacing: CGFloat { StudioLayout.panelSpacing }
    var panelPadding: CGFloat { 12 }
    var minimumControlHeight: CGFloat { StudioLayout.minimumTouchTarget }

    var columnCount: Int {
        let usableWidth = max(availableWidth - horizontalPadding * 2, 0)
        if usableWidth >= 880 { return 3 }
        if usableWidth >= 600 { return 2 }
        return 1
    }

    var contentColumnWidth: CGFloat {
        let usableWidth = max(availableWidth - horizontalPadding * 2, 0)
        let totalSpacing = CGFloat(max(columnCount - 1, 0)) * panelSpacing
        return max((usableWidth - totalSpacing) / CGFloat(columnCount), 260)
    }

    var contentColumns: [MIDISettingsContentColumn] {
        [
            MIDISettingsContentColumn(panel: .routing, width: contentColumnWidth),
            MIDISettingsContentColumn(panel: .bluetooth, width: contentColumnWidth),
            MIDISettingsContentColumn(panel: .network, width: contentColumnWidth)
        ]
    }

    var estimatedContentHeight: CGFloat {
        let headerHeight: CGFloat = 58
        let tallestPanelHeight: CGFloat = columnCount >= 3 ? 430 : 486
        let rows = CGFloat((contentColumns.count + columnCount - 1) / columnCount)
        return headerHeight + verticalSpacing + tallestPanelHeight * rows + panelSpacing * max(rows - 1, 0)
    }
}
