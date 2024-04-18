//
//  SubscriptionManager.swift
//

import AVFoundation
import Foundation
import MillicastSDK
import os

public protocol SubscriptionManagerProtocol: AnyObject {
    var state: AsyncStream<MCSubscriber.State> { get }
    var statsReport: AsyncStream<MCStatsReport> { get }
    var activity: AsyncStream<MCSubscriber.ActivityEvent> { get }
    var tracks: AsyncStream<TrackEvent> { get }
    var layers: AsyncStream<LayersEvent> { get }

    func connect(streamName: String, accountID: String) async throws -> Bool
    func startSubscribe() async throws -> Bool
    func stopSubscribe() async throws -> Bool
    func selectLayer(layer: MCLayerData?) async throws -> Bool
}

public final class SubscriptionManager: SubscriptionManagerProtocol {
    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: SubscriptionManager.self)
    )

    private let subscriber: MCSubscriber

    public lazy var state: AsyncStream<MCSubscriber.State> = subscriber.state()
    public lazy var statsReport: AsyncStream<MCStatsReport> = subscriber.statsReport()
    public lazy var activity: AsyncStream<MCSubscriber.ActivityEvent> = subscriber.activity()
    public lazy var tracks: AsyncStream<TrackEvent> = subscriber.tracks()
    public lazy var layers: AsyncStream<LayersEvent> = subscriber.layers()

    public init() {
        subscriber = MCSubscriber()
    }

    public func connect(streamName: String, accountID: String) async throws -> Bool {
        Self.logger.debug("Start a new connect request")

        let isConnected = await subscriber.isConnected()
        let isSubscribed = await subscriber.isSubscribed()
        guard !isSubscribed, !isConnected else {
            Self.logger.debug("Returning as the subscriber is already subscribed or connected")
            return false
        }

        try await subscriber.setCredentials(makeCredentials(streamName: streamName, accountID: accountID))

        try await subscriber.connect()

        Self.logger.debug("Connection successful")
        return true
    }

    public func startSubscribe() async throws -> Bool {
        Self.logger.debug("Start a subscription")

        let isConnected = await subscriber.isConnected()
        guard isConnected else {
            Self.logger.debug("Returning as the subscriber is not connected")
            return false
        }

        let isSubscribed = await subscriber.isSubscribed()
        guard !isSubscribed else {
            Self.logger.debug("Returning as the subscriber is already subscribed")
            return false
        }

        await subscriber.enableStats(true)

        try await subscriber.subscribe()

        Self.logger.debug("Subscription successful")

        return true
    }

    public func stopSubscribe() async throws -> Bool {
        Self.logger.debug("Stop subscription")

        await subscriber.enableStats(false)

        try await subscriber.unsubscribe()

        try await subscriber.disconnect()

        Self.logger.debug("Successfully stopped subscription")
        return true
    }

    public func selectLayer(layer: MCLayerData?) async throws -> Bool {
        try await subscriber.select(layer)
        return true
    }
}

// MARK: Maker functions

private extension SubscriptionManager {

    var clientOptions: MCClientOptions {
        let optionsSub = MCClientOptions()
        optionsSub.statsDelayMs = 1000

        return optionsSub
    }

    func makeCredentials(streamName: String, accountID: String) -> MCSubscriberCredentials {
        let credentials = MCSubscriberCredentials()
        credentials.apiUrl = "https://director.millicast.com/api/director/subscribe"
        credentials.accountId = accountID
        credentials.streamName = streamName
        credentials.token = ""

        return credentials
    }
}
