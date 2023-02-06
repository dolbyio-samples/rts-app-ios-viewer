//
//  MockRTSDataStore.swift
//

import Foundation
import MillicastSDK
import RTSComponentKit

final class MockRTSDataStore: RTSDataStore {

    enum Event: Equatable {
        case toggleAudioState
        case setAudio(enable: Bool)
        case toggleVideoState
        case setVideo(enable: Bool)
        case setVolume(volume: Double)
        case connect
        case connectWith(streamName: String, accountID: String)
        case startSubscribe
        case stopSubscribe
        case subscriptionView
        case selectLayer(streamType: StreamType)
    }
    private(set) var events: [Event] = []

    override init(
        subscriptionManager: SubscriptionManagerProtocol = MockSubscriptionManager(),
        videoRenderer: MCIosVideoRenderer = MCIosVideoRenderer()
    ) {
        super.init(subscriptionManager: subscriptionManager, videoRenderer: videoRenderer)
    }

    override func toggleAudioState() {
        events.append(.toggleAudioState)
    }

    override func setAudio(_ enable: Bool) {
        events.append(.setAudio(enable: enable))
    }

    override func toggleVideoState() {
        events.append(.toggleVideoState)
    }

    override func setVideo(_ enable: Bool) {
        events.append(.setVideo(enable: enable))
    }

    override func setVolume(_ volume: Double) {
        events.append(.setVolume(volume: volume))
    }

    var connectStateToReturn = true
    override func connect() async -> Bool {
        events.append(.connect)
        return connectStateToReturn
    }

    var connectWithCredentialsStateToReturn = true
    override func connect(streamName: String, accountID: String) async -> Bool {
        events.append(.connectWith(streamName: streamName, accountID: accountID))
        return connectWithCredentialsStateToReturn
    }

    var startSubscribeStateToReturn = true
    override func startSubscribe() async -> Bool {
        events.append(.startSubscribe)
        return startSubscribeStateToReturn
    }

    var stopSubscribeStateToReturn = true
    override func stopSubscribe() async -> Bool {
        events.append(.stopSubscribe)
        return stopSubscribeStateToReturn
    }

    var subscriptionViewToReturn = UIView()
    override func subscriptionView() -> UIView {
        events.append(.subscriptionView)
        return subscriptionViewToReturn
    }

    var selectLayerStateToReturn = true
    override func selectLayer(streamType: StreamType) -> Bool {
        events.append(.selectLayer(streamType: streamType))
        return selectLayerStateToReturn
    }
}
