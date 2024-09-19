//
//  Channel.swift
//

import Foundation
import RTSCore

struct Channel: Identifiable {
    let id = UUID()
    let streamDetail: StreamPair
    let subscriptionManager: SubscriptionManager
    let rendererRegistry: RendererRegistry
}

struct SourcedChannel: Identifiable {
    let id: UUID
    let streamDetail: StreamPair
    let subscriptionManager: SubscriptionManager
    let rendererRegistry: RendererRegistry
    let videoSource: StreamSource
    let audioSource: StreamSource?
}

extension SourcedChannel {
    static func build(from channel: Channel, videoSource: StreamSource, audioSource: StreamSource?) -> SourcedChannel {
        return SourcedChannel(id: channel.id,
                              streamDetail: channel.streamDetail,
                              subscriptionManager: channel.subscriptionManager,
                              rendererRegistry: channel.rendererRegistry,
                              videoSource: videoSource,
                              audioSource: audioSource)
    }
}
