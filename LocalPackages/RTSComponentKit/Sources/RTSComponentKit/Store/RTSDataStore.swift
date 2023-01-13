//
//  RTSDataStore.swift
//  RTSViewer
//

import Foundation
import MillicastSDK
import SwiftUI

public final class RTSDataStore: ObservableObject {

    public enum SubscribeState: Equatable {
        case streamInactive
        case streamActive
        case connected
        case subscribed
        case disconnected
        case error(SubscriptionError)
    }

    public enum SubscriptionError: Error, Equatable {
        case subscribeError(reason: String)
        case connectError(reason: String)
    }

    @Published public private(set) var subscribeState: SubscribeState = .disconnected
    @Published public private(set) var isSubscribeAudioEnabled: Bool = true
    @Published public private(set) var isSubscribeVideoEnabled: Bool = true

    private let subscriptionManager: SubscriptionManager
    private let listener: MCSubscriberListener
    private let subscriptionVideoRenderer: MCIosVideoRenderer
    private var audioTrack: MCAudioTrack?
    private var videoTrack: MCVideoTrack?

    init(subscriptionManager: SubscriptionManager, listener: MCSubscriberListener, subscriptionVideoRenderer: MCIosVideoRenderer) {
        self.subscriptionManager = subscriptionManager
        self.listener = listener
        self.subscriptionVideoRenderer = subscriptionVideoRenderer
    }

    public convenience init() {
        let listener = SubscriptionListener()
        self.init(
            subscriptionManager: SubscriptionManager(listener: listener),
            listener: listener,
            subscriptionVideoRenderer: MCIosVideoRenderer(colorRangeExpansion: false)
        )
        listener.delegate = self
    }

    // MARK: Subscribe API methods

    @discardableResult
    public func toggleAudioState() -> Bool {
        setAudio(!isSubscribeAudioEnabled)
    }

    @discardableResult
    public func setAudio(_ isEnabled: Bool) -> Bool {
        switch subscribeState {
        case .connected:
            subscriptionManager.enableAudio(for: audioTrack, enable: isEnabled)
            isSubscribeAudioEnabled = isEnabled
            return true

        default:
            return false
        }
    }

    @discardableResult
    public func toggleVideoState() -> Bool {
        setVideo(!isSubscribeVideoEnabled)
    }

    @discardableResult
    public func setVideo(_ isEnabled: Bool) -> Bool {
        switch subscribeState {
        case .connected:
            subscriptionManager.enableVideo(for: videoTrack, enable: isEnabled)
            isSubscribeVideoEnabled = isEnabled
            return true

        default:
            return false
        }
    }

    @discardableResult
    public func setVolume(_ volume: Double) -> Bool {
        guard
            case .connected = subscribeState,
            let audioTrack = audioTrack
        else {
            return false
        }
        return subscriptionManager.setAudioTrackVolume(volume, audioTrack: audioTrack)
    }

    public func connect(streamName: String, accountID: String) async -> Bool {
        await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    public func connect() async -> Bool {
        await subscriptionManager.connect()
    }

    public func startSubscribe() async -> Bool {
        await subscriptionManager.startSubscribe()
    }

    public func stopSubscribe() async -> Bool {
        let success = await subscriptionManager.stopSubscribe()

        setAudio(false)
        setVideo(false)

        await subscriptionManager.stopRender(of: videoTrack, on: subscriptionVideoRenderer)

        self.audioTrack = nil
        self.videoTrack = nil

        Task {
            await MainActor.run {
                subscribeState = .disconnected
            }
        }

        return success
    }

    public func subscriptionView() -> UIView {
        subscriptionVideoRenderer.getView()
    }
}

// MARK: SubscriptionListenerDelegate implementation

extension RTSDataStore: SubscriptionListenerDelegate {
    func onStreamActive() {
        Task {
            await MainActor.run {
                subscribeState = .streamActive
            }
        }
    }

    func onStreamInactive() {
        Task {
            await MainActor.run {
                subscribeState = .streamInactive
            }
        }
    }

    func onStreamStopped() {
        Task {
            await MainActor.run {
                subscribeState = .streamInactive
            }
        }
    }

    func onSubscribed() {
        Task {
            await MainActor.run {
                subscribeState = .subscribed
            }
        }
    }

    func onSubscribedError(_ reason: String) {
        Task {
            await MainActor.run {
                subscribeState = .error(.subscribeError(reason: reason))
            }
        }
    }

    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        Task {
            await MainActor.run {
                renderVideoTrack(track)
            }
        }
    }

    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        Task {
            await MainActor.run {
                renderAudioTrack(track)
            }
        }
    }

    func onConnected() {
        Task {
            await MainActor.run {
                subscribeState = .connected
            }
        }
    }

    func onConnectionError(reason: String) {
        Task {
            await MainActor.run {
                subscribeState = .error(.connectError(reason: reason))
            }
        }
    }
}

// MARK: Render handler's for Audio and Video Tracks

private extension RTSDataStore {

    private func renderVideoTrack(_ videoTrack: MCVideoTrack?) {
        self.videoTrack = videoTrack
        setVideo(true)
        Task {
            await subscriptionManager.startRender(of: videoTrack, on: subscriptionVideoRenderer)
        }
    }

    private func renderAudioTrack(_ audioTrack: MCAudioTrack?) {
        self.audioTrack = audioTrack
        setAudio(true)
        Task {
            await subscriptionManager.renderAudioTrack(audioTrack)
        }
    }
}
