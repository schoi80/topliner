import Foundation
import Observation
#if canImport(CoreMIDI)
import CoreMIDI
#endif

enum NetworkMIDIConnectionPolicy: Equatable, CaseIterable, Identifiable {
    case contactsOnly
    case anyone

    var id: String { label }

    var label: String {
        switch self {
        case .contactsOnly: "Contacts Only"
        case .anyone: "Anyone"
        }
    }
}

protocol NetworkMIDISessionManaging: AnyObject {
    var isEnabled: Bool { get set }
    var connectionPolicy: NetworkMIDIConnectionPolicy { get set }
    var isAvailable: Bool { get }
    var localName: String? { get }
}

@Observable
final class NetworkMIDIService {
    private let session: NetworkMIDISessionManaging

    private(set) var isEnabled: Bool
    private(set) var connectionPolicy: NetworkMIDIConnectionPolicy

    init(session: NetworkMIDISessionManaging = CoreNetworkMIDISessionAdapter()) {
        self.session = session
        isEnabled = session.isEnabled
        connectionPolicy = session.connectionPolicy
    }

    var canEnableNetworkMIDI: Bool {
        session.isAvailable
    }

    var availabilityMessage: String {
        if session.isAvailable {
            "Network MIDI is available on this device."
        } else {
            "Network MIDI is not available on this device."
        }
    }

    var instructions: String {
        let localName = session.localName ?? "this iPhone or iPad"
        return "Enable Network MIDI, then open Audio MIDI Setup on macOS, choose MIDI Studio, open Network, create or join an RTP-MIDI session, and connect to \(localName)."
    }

    func setEnabled(_ enabled: Bool) {
        guard session.isAvailable else {
            session.isEnabled = false
            isEnabled = false
            return
        }
        session.connectionPolicy = connectionPolicy
        session.isEnabled = enabled
        isEnabled = enabled
    }

    func setConnectionPolicy(_ policy: NetworkMIDIConnectionPolicy) {
        connectionPolicy = policy
        session.connectionPolicy = policy
    }
}

final class CoreNetworkMIDISessionAdapter: NetworkMIDISessionManaging {
    #if canImport(CoreMIDI)
    private let session: MIDINetworkSession?
    #endif

    init() {
        #if canImport(CoreMIDI)
        session = MIDINetworkSession.default()
        #endif
    }

    var isAvailable: Bool {
        #if canImport(CoreMIDI)
        session != nil
        #else
        false
        #endif
    }

    var localName: String? {
        #if canImport(CoreMIDI)
        session?.networkName
        #else
        nil
        #endif
    }

    var isEnabled: Bool {
        get {
            #if canImport(CoreMIDI)
            session?.isEnabled ?? false
            #else
            false
            #endif
        }
        set {
            #if canImport(CoreMIDI)
            session?.isEnabled = newValue
            #endif
        }
    }

    var connectionPolicy: NetworkMIDIConnectionPolicy {
        get {
            #if canImport(CoreMIDI)
            guard let session else { return .contactsOnly }
            return session.connectionPolicy == .anyone ? .anyone : .contactsOnly
            #else
            return .contactsOnly
            #endif
        }
        set {
            #if canImport(CoreMIDI)
            switch newValue {
            case .contactsOnly:
                session?.connectionPolicy = .hostsInContactList
            case .anyone:
                session?.connectionPolicy = .anyone
            }
            #endif
        }
    }
}
