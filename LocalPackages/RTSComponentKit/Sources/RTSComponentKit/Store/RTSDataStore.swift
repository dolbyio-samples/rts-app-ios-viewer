//
//  RTSDataStore.swift
//  RTSViewer
//

import Foundation
import MillicastSDK
import SwiftUI

public final class RTSDataStore: ObservableObject {

    public enum SubscriptionError: Error, Equatable {
        case subscribeError(reason: String)
        case connectError(reason: String)
    }

    public enum State: Equatable {
        case streamInactive
        case streamActive
        case connected
        case subscribed
        case disconnected
        case error(SubscriptionError)
    }

    @Published public private(set) var subscribeState: State = .disconnected
    @Published public private(set) var isAudioEnabled: Bool = true
    @Published public private(set) var isVideoEnabled: Bool = true

    private let videoRenderer: MCIosVideoRenderer
    private var subscriptionManager: SubscriptionManager!

    private typealias StreamDetail = (streamName: String, accountID: String)
    private var streamDetail: StreamDetail?
    private var audioTrack: MCAudioTrack?
    private var videoTrack: MCVideoTrack?

    @Published public private(set) var layerActiveMap: [MCLayerData]?

    init(subscriptionManager: SubscriptionManager, videoRenderer: MCIosVideoRenderer) {
        self.subscriptionManager = subscriptionManager
        self.videoRenderer = videoRenderer
        self.subscriptionManager.delegate = self
    }

    public convenience init() {
        self.init(
            subscriptionManager: SubscriptionManager(),
            videoRenderer: MCIosVideoRenderer()
        )
        self.subscriptionManager.delegate = self
    }

    // MARK: Subscribe API methods

    public func toggleAudioState() {
        setAudio(!isAudioEnabled)
    }

    public func setAudio(_ enable: Bool) {
        audioTrack?.enable(enable)
        Task {
            await MainActor.run {
                isAudioEnabled = enable
            }
        }
    }

    public func toggleVideoState() {
        setVideo(!isVideoEnabled)
    }

    public func setVideo(_ enable: Bool) {
        videoTrack?.enable(enable)
        Task {
            await MainActor.run {
                isVideoEnabled = enable
            }
        }
    }

    public func setVolume(_ volume: Double) {
        audioTrack?.setVolume(volume)
    }

    public func connect() async -> Bool {
        guard let streamDetail = streamDetail else {
            return false
        }

        return await connect(streamName: streamDetail.streamName, accountID: streamDetail.accountID)
    }

    public func connect(streamName: String, accountID: String) async -> Bool {
        self.streamDetail = (streamName: streamName, accountID: accountID)
        return await subscriptionManager.connect(streamName: streamName, accountID: accountID)
    }

    public func startSubscribe() async -> Bool {
        await subscriptionManager.startSubscribe()
    }

    public func stopSubscribe() async -> Bool {
        let success = await subscriptionManager.stopSubscribe()

        setAudio(false)
        setVideo(false)

        audioTrack = nil
        videoTrack = nil

        videoTrack?.remove(videoRenderer)

        updateState(to: .disconnected)

        return success
    }

    public func subscriptionView() -> UIView {
        videoRenderer.getView()
    }

    @discardableResult
    public func selectLayer(streamType: StreamType) -> Bool {
        switch streamType {
        case .auto:
            return subscriptionManager.selectLayer(layer: nil)
        case .high:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[0])
        case .medium:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[1])
        case .low:
            return subscriptionManager.selectLayer(layer: layerActiveMap?[2])
        }
    }
}

// MARK: SubscriptionManagerDelegate implementation

extension RTSDataStore: SubscriptionManagerDelegate {

    public func onStreamActive() {
        updateState(to: .streamActive)
    }

    public func onStreamInactive() {
        updateState(to: .streamInactive)
    }

    public func onStreamStopped() {
        updateState(to: .streamInactive)
    }

    public func onSubscribed() {
        updateState(to: .subscribed)
    }

    public func onSubscribedError(_ reason: String) {
        updateState(to: .error(.subscribeError(reason: reason)))
    }

    public func onVideoTrack(_ track: MCVideoTrack, withMid mid: String) {
        videoTrack = track
        setVideo(true)
        track.add(videoRenderer)
    }

    public func onAudioTrack(_ track: MCAudioTrack, withMid mid: String) {
        audioTrack = track
        setAudio(true)
        // Configure the AVAudioSession with our settings.
        Utils.configureAudioSession()
    }

    public func onConnected() {
        updateState(to: .connected)
    }

    public func onConnectionError(reason: String) {
        updateState(to: .error(.connectError(reason: reason)))
    }

    public func updateState(to state: State) {
        Task {
            await MainActor.run {
                self.subscribeState = state
            }
        }
    }

    func onStreamLayers(_ mid: String?, activeLayers: [MCLayerData]?, inactiveLayers: [MCLayerData]?) {
        Task {
            await MainActor.run {
                layerActiveMap = activeLayers
            }
        }
    }
}
