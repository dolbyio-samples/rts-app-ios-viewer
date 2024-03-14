//
//  MockSubscriptionManager.swift
//

@testable import RTSComponentKit

import Foundation
import MillicastSDK

final class MockSubscriptionManager: SubscriptionManagerProtocol {
    lazy var state: AsyncStream<MCSubscriber.State> = stateStream
    lazy var statsReport: AsyncStream<MCStatsReport> = statsReportStream
    lazy var activity: AsyncStream<MCSubscriber.ActivityEvent> = activityStream
    lazy var tracks: AsyncStream<MillicastSDK.TrackEvent> = tracksStream
    lazy var layers: AsyncStream<MillicastSDK.LayersEvent> = layersStream

    private var stateStream: AsyncStream<MCSubscriber.State>!
    private var statsReportStream: AsyncStream<MCStatsReport>!
    private var activityStream: AsyncStream<MCSubscriber.ActivityEvent>!
    private var tracksStream: AsyncStream<MillicastSDK.TrackEvent>!
    private var layersStream: AsyncStream<MillicastSDK.LayersEvent>!

    private(set) var stateContinuation: AsyncStream<MCSubscriber.State>.Continuation!
    private(set) var statsReportContinuation: AsyncStream<MCStatsReport>.Continuation!
    private(set) var activityContinuation: AsyncStream<MCSubscriber.ActivityEvent>.Continuation!
    private(set) var tracksContinuation: AsyncStream<MillicastSDK.TrackEvent>.Continuation!
    private(set) var layersContinuation: AsyncStream<MillicastSDK.LayersEvent>.Continuation!

    enum Event: Equatable {
        case connect(streamName: String, accountID: String)
        case startSubscribe
        case stopSubscribe
        case selectLayer(layer: MCLayerData?)
    }
    private(set) var events: [Event] = []

    init() {
        stateStream = AsyncStream { continuation in
            stateContinuation = continuation
        }

        statsReportStream = AsyncStream { continuation in
            statsReportContinuation = continuation
        }

        activityStream = AsyncStream { continuation in
            activityContinuation = continuation
        }

        tracksStream = AsyncStream { continuation in
            tracksContinuation = continuation
        }

        layersStream = AsyncStream { continuation in
            layersContinuation = continuation
        }
    }
    
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
