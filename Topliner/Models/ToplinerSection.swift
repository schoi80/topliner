enum ToplinerSection: String, CaseIterable, Identifiable, Equatable {
    case compose
    case capture
    case projects
    case midi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compose: "Compose"
        case .capture: "Capture"
        case .projects: "Projects"
        case .midi: "MIDI"
        }
    }

    var systemImage: String {
        switch self {
        case .compose: "pianokeys"
        case .capture: "mic"
        case .projects: "folder"
        case .midi: "cable.connector"
        }
    }
}
