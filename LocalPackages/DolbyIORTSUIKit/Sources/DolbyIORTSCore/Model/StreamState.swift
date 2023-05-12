//
//  StreamState.swift
//

import Foundation

public enum StreamState {
    case disconnected
    case connecting
    case connected
    case subscribing
    case subscribed(sources: [StreamSource], viewerCount: Int)
    case stopped
    case error(StreamError)

    init(state: State) {
        switch state {
        case .disconnected:
            self = .disconnected

        case .connecting:
            self = .connecting

        case .connected:
            self = .connected

        case let .subscribed(state):
            self = .subscribed(sources: state.sources, viewerCount: state.viewerCount)

        case .stopped:
            self = .stopped

        case let .error(state):
            self = .error(state.error)

        case .subscribing:
            self = .subscribing
        }
    }
}
