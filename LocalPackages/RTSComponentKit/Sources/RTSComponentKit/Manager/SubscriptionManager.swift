//
//  SubscriptionManager.swift
//  RTSViewer
//

import AVFoundation
import Foundation
import MillicastSDK

public final class SubscriptionManager: ObservableObject {

    private let listener: MCSubscriberListener

    private let queueLabelKey = DispatchSpecificKey<String>()
    private let queueSub = DispatchQueue(label: "mc-QSub", qos: .userInitiated)

    init(listener: MCSubscriberListener) {
        self.listener = listener
    }

    private lazy var subscriber: MCSubscriber? = {
        guard let subscriber = MCSubscriber.create() else {
            return nil
        }
        subscriber.setListener(listener)

        return subscriber
    }()

    public func enableAudio(for track: MCAudioTrack?, enable: Bool) {
        track?.enable(enable)
    }

    public func enableVideo(for track: MCVideoTrack?, enable: Bool) {
        track?.enable(enable)
    }

    public func renderAudioTrack(_ track: MCAudioTrack?) async {
        let task = {
            guard track != nil else {
                return
            }
            // Configure the AVAudioSession with our settings.
            Utils.configureAudioSession()
        }
        runOnQueue(log: "Render subscribe audio", task, queueSub)
    }

    public func setAudioTrackVolume(_ volume: Double, audioTrack: MCAudioTrack) -> Bool {
        guard let subscriber = subscriber, subscriber.isSubscribed() else {
            return false
        }
        audioTrack.setVolume(volume)
        return true
    }

    public func connect() async -> Bool {
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

    public func connect(streamName: String, accountID: String) async -> Bool {
        let task = { [weak self] in
            guard let self = self, let subscriber = self.subscriber else {
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
        }

        runOnQueue(log: "Connect Subscriber", task, queueSub)
        return true
    }

    public func startSubscribe() async -> Bool {
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

    public func stopSubscribe() async -> Bool {
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

    public func startRender(of track: MCVideoTrack?, on renderer: MCIosVideoRenderer) async {
        let task = {
            guard let track = track else {
                return
            }
            track.add(renderer)
        }
        runOnQueue(log: "Render subscribe video", task, queueSub)
    }

    public func stopRender(of track: MCVideoTrack?, on renderer: MCIosVideoRenderer) async {
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
