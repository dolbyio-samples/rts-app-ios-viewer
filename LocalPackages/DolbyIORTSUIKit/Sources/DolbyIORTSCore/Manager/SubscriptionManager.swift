//
//  SubscriptionManager.swift
//

import Foundation
import MillicastSDK
import os
import AVFAudio

protocol SubscriptionManagerDelegate: AnyObject {
    func onSubscribed()

    func onSubscribedError(_ reason: String)

    func onVideoTrack(_ track: MCVideoTrack, withMid mid: String)

    func onAudioTrack(_ track: MCAudioTrack, withMid mid: String)

    func onActive(_ streamId: String, tracks: [String], sourceId: String?)

    func onInactive(_ streamId: String, sourceId: String?)

    func onStopped()

    func onLayers(_ mid: String, activeLayers: [MCLayerData], inactiveLayers: [MCLayerData])

    func onConnected()

    func onConnectionError(_ status: Int32, withReason reason: String)

    func onSignalingError(_ message: String)

    func onStatsReport(_ report: MCStatsReport)

    func onViewerCount(_ count: Int32)
}

protocol SubscriptionManagerProtocol: AnyObject {
    var delegate: SubscriptionManagerDelegate? { get set }

    func connect(streamName: String, accountID: String) async -> Bool
    func startSubscribe() async -> Bool
    func stopSubscribe() async -> Bool
    func selectVideoQuality(_ quality: StreamSource.VideoQuality, for source: StreamSource)
    func getMid(for trackId: String) -> String?
    func addRemoteTrack(_ sourceBuilder: StreamSourceBuilder)
    func projectVideo(for source: StreamSource, withQuality quality: StreamSource.VideoQuality)
    func unprojectVideo(for source: StreamSource)
    func projectAudio(for source: StreamSource)
    func unprojectAudio(for source: StreamSource)
}

final class SubscriptionManager: SubscriptionManagerProtocol {
    static let rtsCore = Logger(subsystem: "io.dolby.rtscore", category: String(describing: SubscriptionManager.self))

    private var subscriber: MCSubscriber!

    weak var delegate: SubscriptionManagerDelegate?

    func connect(streamName: String, accountID: String) async -> Bool {
        let subscriber = makeSubscriber()
        subscriber.setListener(self)

        Self.rtsCore.debug("Start connect with credentials")

        self.subscriber = subscriber

        guard streamName.count > 0, accountID.count > 0 else {
            Self.rtsCore.warning("Invalid credentials")
            return false
        }

        let task = Task { [weak self] () -> Bool in
            guard let self = self else {
                return false
            }

            guard !self.isSubscribed, !self.isConnected else {
                Self.rtsCore.warning("Already connected or subscribed")
                return false
            }

            let credentials = self.makeCredentials(streamName: streamName, accountID: accountID)

            self.subscriber.setCredentials(credentials)

            guard self.subscriber.connect() else {
                Self.rtsCore.warning("Failed to establish a connection")
                return false
            }

            return true
        }

        return await task.value
    }

    func startSubscribe() async -> Bool {
        let task = Task { [weak self] () -> Bool in
            Self.rtsCore.debug("Start subscribe")

            guard let self = self else {
                return false
            }

            guard self.isConnected else {
                Self.rtsCore.warning("No connection present")
                return false
            }

            guard !self.isSubscribed else {
                Self.rtsCore.warning("Already subscribed")
                return false
            }

            guard self.subscriber.subscribe() else {
                Self.rtsCore.warning("Failed to subscribe")
                return false
            }

            self.subscriber.enableStats(true)
            return true
        }

        return await task.value
    }

    func stopSubscribe() async -> Bool {
        let task = Task { [weak self] () -> Bool in
            Self.rtsCore.debug("Stop subscribe")

            guard let self = self, let subscriber = subscriber else {
                return false
            }
            subscriber.enableStats(false)

            guard subscriber.unsubscribe() else {
                Self.rtsCore.warning("Failed to unsubscribe")
                return false
            }

            guard subscriber.disconnect() else {
                Self.rtsCore.warning("Failed to disconnect")
                return false
            }

            self.subscriber = nil

            return true
        }
        return await task.value
    }

    func selectVideoQuality(_ quality: StreamSource.VideoQuality, for source: StreamSource) {
        projectVideo(for: source, withQuality: quality)
    }

    func getMid(for trackId: String) -> String? {
        subscriber.getMid(trackId)
    }

    func addRemoteTrack(_ sourceBuilder: StreamSourceBuilder) {
        sourceBuilder.supportedTrackItems.forEach { subscriber.addRemoteTrack($0.trackType.rawValue) }
    }

    func projectVideo(for source: StreamSource, withQuality quality: StreamSource.VideoQuality) {
        Self.rtsCore.debug("Project video for source \(source.sourceId.value ?? "N/A")")
        guard let videoTrack = source.videoTrack else {
            return
        }

        let projectionData = MCProjectionData()
        projectionData.media = videoTrack.trackInfo.mediaType.rawValue
        projectionData.mid = videoTrack.trackInfo.mid
        projectionData.trackId = videoTrack.trackInfo.trackType.rawValue
        projectionData.layer = quality.layerData

        subscriber.project(source.sourceId.value, withData: [projectionData])
    }

    func unprojectVideo(for source: StreamSource) {
        Self.rtsCore.debug("Project video for source \(source.sourceId.value ?? "N/A")")
        guard let videoTrack = source.videoTrack else {
            return
        }

        subscriber.unproject([videoTrack.trackInfo.mid])
    }

    func projectAudio(for source: StreamSource) {
        Self.rtsCore.debug("Project audio for source \(source.sourceId.value ?? "N/A")")
        guard let audioTrack = source.audioTracks.first else {
            return
        }

        Utils.configureAudioSession()
        let projectionData = MCProjectionData()
        audioTrack.track.enable(true)
        audioTrack.track.setVolume(1)
        projectionData.media = audioTrack.trackInfo.mediaType.rawValue
        projectionData.mid = audioTrack.trackInfo.mid
        projectionData.trackId = audioTrack.trackInfo.trackType.rawValue

        subscriber.project(source.sourceId.value, withData: [projectionData])
    }

    func unprojectAudio(for source: StreamSource) {
        guard let audioTrack = source.audioTracks.first else {
            return
        }

        subscriber.unproject([audioTrack.trackInfo.mid])
    }
}

// MARK: Maker functions

private extension SubscriptionManager {

    func makeSubscriber() -> MCSubscriber {
        return MCSubscriber.create()
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

// MARK: MCSubscriberListener implementation

extension SubscriptionManager: MCSubscriberListener {

    func onSubscribed() {
        Self.rtsCore.debug("Callback -> onSubscribed")
        delegate?.onSubscribed()
    }

    func onSubscribedError(_ reason: String!) {
        Self.rtsCore.error("Callback -> onSubscribedError \(reason)")
        delegate?.onSubscribedError(reason)
    }

    func onVideoTrack(_ track: MCVideoTrack!, withMid mid: String!) {
        Self.rtsCore.debug("Callback -> onVideoTrack with mid \(mid)")
        delegate?.onVideoTrack(track, withMid: mid)
    }

    func onAudioTrack(_ track: MCAudioTrack!, withMid mid: String!) {
        Self.rtsCore.debug("Callback -> onAudioTrack with mid \(mid)")
        delegate?.onAudioTrack(track, withMid: mid)
    }

    func onActive(_ streamId: String!, tracks: [String]!, sourceId: String!) {
        Self.rtsCore.debug("Callback -> onActive with sourceId \(sourceId ?? "NULL")")
        delegate?.onActive(streamId, tracks: tracks, sourceId: sourceId)
    }

    func onInactive(_ streamId: String!, sourceId: String!) {
        Self.rtsCore.debug("Callback -> onInactive with sourceId \(sourceId ?? "NULL")")
        delegate?.onInactive(streamId, sourceId: sourceId)
    }

    func onStopped() {
        Self.rtsCore.debug("Callback -> onStopped")
        delegate?.onStopped()
    }

    func onVad(_ mid: String!, sourceId: String!) {
        Self.rtsCore.debug("Callback -> onVad with mid \(mid), sourceId \(sourceId)")
    }

    func onLayers(_ mid: String!, activeLayers: [MCLayerData]!, inactiveLayers: [MCLayerData]!) {
        Self.rtsCore.debug("Callback -> onLayers with activeLayers \(activeLayers), inactiveLayers \(inactiveLayers)")
        delegate?.onLayers(mid, activeLayers: activeLayers, inactiveLayers: inactiveLayers)
    }

    func onConnected() {
        Self.rtsCore.debug("Callback -> onConnected")
        delegate?.onConnected()
    }

    func onConnectionError(_ status: Int32, withReason reason: String!) {
        Self.rtsCore.error("Callback -> onConnectionError")
        delegate?.onConnectionError(status, withReason: reason)
    }

    func onSignalingError(_ message: String!) {
        Self.rtsCore.error("Callback -> onSignalingError")
        delegate?.onSignalingError(message)
    }

    func onStatsReport(_ report: MCStatsReport!) {
        Self.rtsCore.debug("Callback -> onStatsReport")
        delegate?.onStatsReport(report)
    }

    func onViewerCount(_ count: Int32) {
        Self.rtsCore.debug("Callback -> onViewerCount")
        delegate?.onViewerCount(count)
    }
}

// MARK: Helper functions

private extension SubscriptionManager {
    var isSubscribed: Bool {
        subscriber.isSubscribed()
    }

    var isConnected: Bool {
        subscriber.isConnected()
    }
}
