//
//  MockRTSDataStore.swift
//

import Foundation
import MillicastSDK
import RTSCore

final class MockRTSDataStore: RTSDataStore {

    enum Event: Equatable {
        case toggleAudioState
        case setAudio(enable: Bool)
        case toggleVideoState
        case setVideo(enable: Bool)
        case setVolume(volume: Double)
        case connectWith(streamName: String, accountID: String)
        case startSubscribe
        case stopSubscribe
        case subscriptionView
        case selectLayer(quality: VideoQuality)
    }
    private(set) var events: [Event] = []

    var connectWithCredentialsStateToReturn = true
    override func connect(
        streamName: String,
        accountID: String,
        subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager()
    ) async throws -> Bool {
        events.append(.connectWith(streamName: streamName, accountID: accountID))
        return connectWithCredentialsStateToReturn
    }

    var startSubscribeStateToReturn = true
    override func startSubscribe() async throws -> Bool {
        events.append(.startSubscribe)
        return startSubscribeStateToReturn
    }

    var stopSubscribeStateToReturn = true
    override func stopSubscribe() async -> Bool {
        events.append(.stopSubscribe)
        return stopSubscribeStateToReturn
    }

    override func selectLayer(videoQuality: VideoQuality) async throws {
        events.append(.selectLayer(quality: videoQuality))
    }
}
