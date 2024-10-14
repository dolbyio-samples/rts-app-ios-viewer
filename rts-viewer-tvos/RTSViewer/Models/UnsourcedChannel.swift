//
//  UnsourcedChannel.swift
//

import Foundation
import RTSCore

struct UnsourcedChannel: Identifiable, Hashable, Equatable {
    let id = UUID()
    let streamConfig: StreamConfig
    let subscriptionManager: SubscriptionManager

    static func == (lhs: UnsourcedChannel, rhs: UnsourcedChannel) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}
