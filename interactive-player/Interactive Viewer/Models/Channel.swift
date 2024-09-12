//
//  Channel.swift
//  Interactive Player
//

import Foundation
import RTSCore

struct Channel: Identifiable {
    let id = UUID()
    let streamDetail: StreamDetail
    let listViewPrimaryVideoQuality: VideoQuality
    let configuration: SubscriptionConfiguration
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager
}

struct SourcedChannel: Identifiable {
    let id: UUID
    let streamDetail: StreamDetail
    let listViewPrimaryVideoQuality: VideoQuality
    let configuration: SubscriptionConfiguration
    let subscriptionManager: SubscriptionManager
    let videoTracksManager: VideoTracksManager
    let source: StreamSource
}

extension SourcedChannel {
    static func build(from channel: Channel, source: StreamSource) -> SourcedChannel {
        return SourcedChannel(id: channel.id,
                              streamDetail: channel.streamDetail,
                              listViewPrimaryVideoQuality: channel.listViewPrimaryVideoQuality,
                              configuration: channel.configuration,
                              subscriptionManager: channel.subscriptionManager,
                              videoTracksManager: channel.videoTracksManager,
                              source: source)
    }
}
