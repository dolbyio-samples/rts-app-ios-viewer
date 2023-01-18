//
//  SubscriptionManager.swift
//  RTSViewer
//

import AVFoundation
import Foundation
import MillicastSDK
import os

protocol SubscriptionManagerDelegate: AnyObject {
    func onSubscribed()
    func onSubscribedError(_ reason: String)
    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String)
    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String)
    func onConnected()
    func onStreamActive()
    func onStreamInactive()
    func onStreamStopped()
    func onConnectionError(reason: String)
}

final class SubscriptionManager {

    private static let logger = Logger(
        subsystem: Bundle.module.bundleIdentifier!,
        category: String(describing: SubscriptionManager.self)
    )

    private var subscriber: MCSubscriber?

    weak var delegate: SubscriptionManagerDelegate?

    func connect(streamName: String, accountID: String) async -> Bool {
        Self.logger.debug("Start a new connect request")

        guard streamName.count > 0, accountID.count > 0 else {
            return false
        }

        let task = Task { [weak self] () -> Bool in
            guard let self = self, let subscriber = self.makeSubscriber() else {
                return false
            }
            self.subscriber = subscriber

            guard !subscriber.isSubscribed(), !subscriber.isConnected() else {
                Self.logger.debug("Returning as the subscriber is already subscribed or connected")
                return false
            }

            subscriber.setCredentials(
                self.makeCredentials(streamName: streamName, accountID: accountID)
            )

            subscriber.setOptions(self.clientOptions)

            guard subscriber.connect() else {
                Self.logger.debug("Failed to connect")
                return false
            }

            Self.logger.debug("Connection successful")
            return true
        }

        return await task.value
    }

    func startSubscribe() async -> Bool {
        Self.logger.debug("Start a subscription")

        let task = Task { [weak self] () -> Bool in
            guard let self = self, let subscriber = self.subscriber else {
                return false
            }

            guard subscriber.isConnected() else {
                Self.logger.debug("Returning as the subscriber is not connected")
                return false
            }

            guard !subscriber.isSubscribed() else {
                Self.logger.debug("Returning as the subscriber is already subscribed")
                return false
            }

            guard subscriber.subscribe() else {
                Self.logger.debug("Failed to subscribe")
                return false
            }

            Self.logger.debug("Subscription successful")
            return true
        }

        return await task.value
    }

    func stopSubscribe() async -> Bool {
        Self.logger.debug("Stop subscription")

        let task = Task { [weak self] () -> Bool in
            guard let self = self, let subscriber = subscriber, isSubscribed else {
                return false
            }

            guard subscriber.unsubscribe() else {
                Self.logger.debug("Failed to unsubscribe")
                return false
            }

            guard subscriber.disconnect() else {
                Self.logger.debug("Failed to disconnect")
                return false
            }

            // Remove Subscriber.
            self.subscriber = nil

            Self.logger.debug("Successfully stopped subscription")
            return true
        }
        return await task.value
    }
}

// MARK: Maker functions

private extension SubscriptionManager {

    func makeSubscriber() -> MCSubscriber? {
        guard let subscriber = MCSubscriber.create() else {
            return nil
        }
        subscriber.setListener(self)

        return subscriber
    }

    var clientOptions: MCClientOptions {
        let optionsSub = MCClientOptions()
        optionsSub.statsDelayMs = 1000

        return optionsSub
    }

    func makeCredentials(streamName: String, accountID: String) -> MCSubscriberCredentials {
        let credentials = MCSubscriberCredentials()
        credentials.accountId = accountID
        credentials.streamName = streamName
        credentials.token = ""
        credentials.apiUrl = "https://director.millicast.com/api/director/subscribe"

        return credentials
    }
}

extension SubscriptionManager: MCSubscriberListener {

    func onSubscribed() {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onSubscribed()")
        delegate?.onSubscribed()
    }

    func onSubscribedError(_ reason: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onSubscribedError(_ reason:)")
        delegate?.onSubscribedError(reason)
    }

    func onVideoTrack(_ track: MCVideoTrack!, withMid mid: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onVideoTrack(_ mid:)")
        delegate?.onVideoTrack(track, withMid: mid)
    }

    func onAudioTrack(_ track: MCAudioTrack!, withMid mid: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onAudioTrack(_ mid:)")
        delegate?.onAudioTrack(track, withMid: mid)
    }

    func onActive(_ streamId: String!, tracks: [String]!, sourceId: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onActive(_ streamId:tracks:sourceId:)")
        delegate?.onStreamActive()
    }

    func onInactive(_ streamId: String!, sourceId: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onInactive(_ streamId:sourceId:)")
        delegate?.onStreamInactive()
    }

    func onStopped() {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onStopped()")
        delegate?.onStreamStopped()
    }

    func onVad(_ mid: String!, sourceId: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onVad(_ mid:sourceId:)")
    }

    func onLayers(_ mid: String!, activeLayers: [MCLayerData]!, inactiveLayers: [MCLayerData]!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onLayers(_ mid:activeLayers:inactiveLayers:)")
    }

    func onConnected() {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onConnected()")
        delegate?.onConnected()
    }

    func onConnectionError(_ status: Int32, withReason reason: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onConnectionError(_ status:withReason:)")
        delegate?.onConnectionError(reason: reason)
    }

    func onSignalingError(_ message: String!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onSignalingError(_ message:)")
    }

    func onStatsReport(_ report: MCStatsReport!) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onStatsReport()")
    }

    func onViewerCount(_ count: Int32) {
        Self.logger.debug("Delegate - \(MCSubscriberListener.self) - onViewerCount(_ count:)")
    }
}

// MARK: Helper functions

private extension SubscriptionManager {

    var isSubscribed: Bool {
        guard let subscriber = subscriber, subscriber.isSubscribed() else {
            return false
        }

        return true
    }
}
