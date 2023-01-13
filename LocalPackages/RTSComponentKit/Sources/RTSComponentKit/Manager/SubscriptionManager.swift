//
//  SubscriptionManager.swift
//  RTSViewer
//

import AVFoundation
import Foundation
import MillicastSDK

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

    private let queueLabelKey = DispatchSpecificKey<String>()
    private let queueSub = DispatchQueue(label: "mc-QSub", qos: .userInitiated)
    private var subscriber: MCSubscriber?

    weak var delegate: SubscriptionManagerDelegate?

    func enableAudio(for track: MCAudioTrack?, enable: Bool) {
        track?.enable(enable)
    }

    func enableVideo(for track: MCVideoTrack?, enable: Bool) {
        track?.enable(enable)
    }

    func renderAudioTrack(_ track: MCAudioTrack?) async {
        let task = {
            guard track != nil else {
                return
            }
            // Configure the AVAudioSession with our settings.
            Utils.configureAudioSession()
        }
        runOnQueue(log: "Render subscribe audio", task, queueSub)
    }

    func setAudioTrackVolume(_ volume: Double, audioTrack: MCAudioTrack) -> Bool {
        guard let subscriber = subscriber, subscriber.isSubscribed() else {
            return false
        }
        audioTrack.setVolume(volume)
        return true
    }

    func connect() async -> Bool {
        let task = { [weak self] in
            guard let self = self, let subscriber = self.subscriber else {
                return
            }

            guard !subscriber.isSubscribed(), !subscriber.isConnected() else {
                return
            }

            subscriber.setOptions(self.clientOptions)

            subscriber.connect()
        }

        runOnQueue(log: "Connect Subscriber", task, queueSub)
        return true
    }

    func connect(streamName: String, accountID: String) async -> Bool {
        let task = { [weak self] in
            guard let self = self, let subscriber = self.makeSubscriber() else {
                return
            }

            guard !subscriber.isSubscribed(), !subscriber.isConnected() else {
                return
            }

            subscriber.setCredentials(
                self.makeCredentials(streamName: streamName, accountID: accountID)
            )

            subscriber.setOptions(self.clientOptions)

            subscriber.connect()

            self.subscriber = subscriber
        }

        runOnQueue(log: "Connect Subscriber", task, queueSub)
        return true
    }

    func startSubscribe() async -> Bool {
        let task = { [weak self] in
            guard let self = self, let subscriber = self.subscriber else {
                return
            }

            guard subscriber.isConnected(), !subscriber.isSubscribed() else {
                return
            }

            subscriber.subscribe()
        }

        runOnQueue(log: "Connect Subscriber", task, queueSub)
        return true
    }

    func stopSubscribe() async -> Bool {
        let task = { [self] in
            guard let subscriber = subscriber, isSubscribed else {
                return
            }

            guard subscriber.unsubscribe() else {
                // TODO: Handle unsubscribe failure
                return
            }

            guard subscriber.disconnect() else {
                // TODO: Handle disconnect failure
                return
            }

            // Remove Subscriber.
            self.subscriber = nil
        }
        runOnQueue(log: "Stop Subscribe", task, queueSub)
        return true
    }

    func startRender(of track: MCVideoTrack?, on renderer: MCIosVideoRenderer) async {
        let task = {
            guard let track = track else {
                return
            }
            track.add(renderer)
        }
        runOnQueue(log: "Render subscribe video", task, queueSub)
    }

    func stopRender(of track: MCVideoTrack?, on renderer: MCIosVideoRenderer) async {
        let task = {
            guard let track = track else {
                return
            }
            track.remove(renderer)
        }
        runOnQueue(log: "Renderer removed from video track.", task, queueSub)
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
        delegate?.onSubscribed()
    }

    func onSubscribedError(_ reason: String!) {
        delegate?.onSubscribedError(reason)
    }

    func onVideoTrack(_ track: MCVideoTrack!, withMid mid: String!) {
        delegate?.onVideoTrack(track, withMid: mid)
    }

    func onAudioTrack(_ track: MCAudioTrack!, withMid mid: String!) {
        delegate?.onAudioTrack(track, withMid: mid)
    }

    func onActive(_ streamId: String!, tracks: [String]!, sourceId: String!) {
        delegate?.onStreamActive()
    }

    func onInactive(_ streamId: String!, sourceId: String!) {
        delegate?.onStreamInactive()
    }

    func onStopped() {
        delegate?.onStreamStopped()
    }

    func onVad(_ mid: String!, sourceId: String!) {
        // TODO:
    }

    func onLayers(_ mid: String!, activeLayers: [MCLayerData]!, inactiveLayers: [MCLayerData]!) {
        // TODO:
    }

    func onConnected() {
        delegate?.onConnected()
    }

    func onConnectionError(_ status: Int32, withReason reason: String!) {
        delegate?.onConnectionError(reason: reason)
    }

    func onSignalingError(_ message: String!) {
        // TODO:
    }

    func onStatsReport(_ report: MCStatsReport!) {
        // TODO:
    }

    func onViewerCount(_ count: Int32) {
        // TODO:
    }
}

// MARK: Helper functions

private extension SubscriptionManager {
    func runOnQueue(log: String = "", _ task: @escaping () -> Void, _ queue: DispatchQueue) {
        queue.async {
            task()
        }
    }

    var isSubscribed: Bool {
        guard let subscriber = subscriber, subscriber.isSubscribed() else {
            return false
        }

        return true
    }
}
