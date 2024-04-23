//
//  StreamState.swift
//

import Foundation

public enum StreamState: Equatable {
    case disconnected
    case connected
    case subscribed(sources: [StreamSource], numberOfStreamViewers: Int)
    case stopped
    case error(StreamError)

    init(state: State) {
        switch state {
        case .disconnected:
            self = .disconnected

        case .connected:
            self = .connected

        case let .subscribed(state):
            let streamSources = state.sources
            if !streamSources.isEmpty {
                self = .subscribed(
                    sources: streamSources,
                    numberOfStreamViewers: state.numberOfStreamViewers
                )
            } else {
                self = .stopped
            }

        case .stopped:
            self = .stopped

        case let .error(state):
            self = .error(state.error)
        }
    }
}
