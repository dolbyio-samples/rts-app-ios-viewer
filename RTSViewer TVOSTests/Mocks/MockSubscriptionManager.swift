//
//  MockSubscriptionManager.swift
//

import Foundation
import MillicastSDK
import RTSComponentKit

final class MockSubscriptionManager: SubscriptionManagerProtocol {

    enum Event: Equatable {
        case connect(streamName: String, accountID: String)
        case startSubscribe
        case stopSubscribe
        case selectLayer(layer: MCLayerData?)
    }
    private(set) var events: [Event] = []

    var delegate: RTSComponentKit.SubscriptionManagerDelegate?

    var connectionSuccessStateToReturn = true
    func connect(streamName: String, accountID: String) async -> Bool {
        events.append(.connect(streamName: streamName, accountID: accountID))
        return connectionSuccessStateToReturn
    }

    var startSubscriptionStateToReturn = true
    func startSubscribe() async -> Bool {
        events.append(.startSubscribe)
        return startSubscriptionStateToReturn
    }

    var stopSubscriptionStateToReturn = true
    func stopSubscribe() async -> Bool {
        events.append(.stopSubscribe)
        return stopSubscriptionStateToReturn
    }

    var selectLayerStateToReturn = true
    func selectLayer(layer: MCLayerData?) -> Bool {
        events.append(.selectLayer(layer: layer))
        return selectLayerStateToReturn
    }
}
