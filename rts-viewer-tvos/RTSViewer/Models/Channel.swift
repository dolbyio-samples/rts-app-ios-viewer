//
//  Channel.swift
//

import Foundation
import RTSCore

struct Channel: Identifiable, Hashable, Equatable {
    let id = UUID()
    let streamConfig: StreamConfig
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}

struct SourcedChannel: Identifiable, Hashable, Equatable {
    let id: UUID
    let streamConfig: StreamConfig
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager
    let source: StreamSource

    static func == (lhs: SourcedChannel, rhs: SourcedChannel) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}

extension SourcedChannel {
    static func build(from channel: Channel, source: StreamSource) -> SourcedChannel {
        return SourcedChannel(id: channel.id,
                              streamConfig: channel.streamConfig,
                              subscriptionManager: channel.subscriptionManager,
                              videoTracksManager: channel.videoTracksManager,
                              source: source)
    }
}
